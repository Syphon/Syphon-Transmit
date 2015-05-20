/*******************************************************************/
/*                                                                 */
/*                      ADOBE CONFIDENTIAL                         */
/*                   _ _ _ _ _ _ _ _ _ _ _ _ _                     */
/*                                                                 */
/* Copyright 2012 Adobe Systems Incorporated					   */
/* All Rights Reserved.                                            */
/*                                                                 */
/* NOTICE:  All information contained herein is, and remains the   */
/* property of Adobe Systems Incorporated and its suppliers, if    */
/* any.  The intellectual and technical concepts contained         */
/* herein are proprietary to Adobe Systems Incorporated and its    */
/* suppliers and may be covered by U.S. and Foreign Patents,       */
/* patents in process, and are protected by trade secret or        */
/* copyright law.  Dissemination of this information or            */
/* reproduction of this material is strictly forbidden unless      */
/* prior written permission is obtained from Adobe Systems         */
/* Incorporated.                                                   */
/*                                                                 */
/*******************************************************************/


#include "TransmitterPlugin.h"
#include <stdio.h>
#include <ctime>
using namespace SDK;

struct ClockInstanceData {
	PrTime						startTime;
	PrTime						ticksPerSecond;
	PrTime						videoFrameRate;
	tmClockCallback				clockCallback;
	void **						callbackContextPtr;
	PrPlayID					playID;
	float						audioSampleRate;
	float **					audioBuffers;
	SDKSuites					suites;
};

	/* This plug-in defined function is called on a new thread when StartPlaybackClock is called.
	** It loops continuously, calling the tmClockCallback at regular intervals until playback ends.
	** We try to make a call at same frequency as the frame rate of the timeline (i.e. transmit instance)
	** TRICKY: How does the function know when playback ends and it should end the loop?
	** Answer: The ClockInstanceData passed in contains a pointer to the callbackContext.
	** When playback ends, the context is set to zero, and that's how it knows to end the loop. 
	*/
	void UpdateClock(
		void* inInstanceData,
		csSDK_int32 inPluginID,
		prSuiteError inStatus)
	{
		ClockInstanceData	*clockInstanceData	= 0;
		clock_t				latestClockTime = clock();
		PrTime				timeElapsed = 0;
		int					audioSampleCount = 0;
		
		clockInstanceData = reinterpret_cast<ClockInstanceData*>(inInstanceData);

		// Calculate how long to wait in between clock updates
		clock_t timeBetweenClockUpdates = (clock_t)(clockInstanceData->videoFrameRate * CLOCKS_PER_SEC / clockInstanceData->ticksPerSecond);

		NSLog(		@"New clock started with callback context 0x%llx.",
					(long long)*clockInstanceData->callbackContextPtr);

		// Loop as long as we have a valid clock callback.
		// It will be set to NULL when playback stops and this function can return.
		while (clockInstanceData->clockCallback && *clockInstanceData->callbackContextPtr)
		{
			// Calculate time elapsed since last time we checked the clock
			clock_t newTime = clock();
			clock_t tempTimeElapsed = newTime - latestClockTime;
			latestClockTime = newTime;

			// Convert tempTimeElapsed to PrTime
			timeElapsed = tempTimeElapsed * clockInstanceData->ticksPerSecond / CLOCKS_PER_SEC;

			// How many audio samples shall we request?  Calculate the number of audio samples in one frame
			audioSampleCount = (int) (clockInstanceData->audioSampleRate * clockInstanceData->videoFrameRate / clockInstanceData->ticksPerSecond);
			if (audioSampleCount > AUDIO_BUFFER_SIZE)
			{
				// If we get here, we underestimated the size of the audio buffer, and may need to adjust it higher.
				NSLog(@"AUDIO_BUFFER_SIZE too small.");

				audioSampleCount = AUDIO_BUFFER_SIZE;
			}

			// Request the audio!  But... we don't do anything with it for now.  At least we know if it's valid.
			clockInstanceData->suites.PlayModuleAudioSuite->GetNextAudioBuffer(clockInstanceData->playID, 0, clockInstanceData->audioBuffers, audioSampleCount);

//			NSLog(		@"Clock callback made. %llu ticks, or %lu microseconds elapsed. Sleeping for %lu microseconds.",
//						timeElapsed,
//						tempTimeElapsed,
//						timeBetweenClockUpdates);

			clockInstanceData->clockCallback(*clockInstanceData->callbackContextPtr, timeElapsed);

			// Sleep for a frame's length
			usleep(timeBetweenClockUpdates / 2); // Try sleeping for the half the time, since Mac OS seems to oversleep :)
		}

		NSLog(		@"Clock with callback context %llx exited.",
					(long long)*clockInstanceData->callbackContextPtr);

		delete(clockInstanceData);
	}


////
//// TransmitInstance methods
////

	/*
	**
	*/
	TransmitInstance::TransmitInstance(
		const tmInstance* inInstance,
		const SDKDevicePtr& inDevice,
		const SDKSettings& inSettings,
		const SDKSuites& inSuites,
        SyphonServer* syphonServer     )
		:
		mDevice(inDevice),
		mSettings(inSettings),
		mSuites(inSuites)
	{
		mClockCallback = 0;
		mCallbackContext = 0;
		mUpdateClockRegistration = 0;
		mPlaying = kPrFalse;

        if(syphonServer)
        {
            NSLog(@"Assigning Plugin Syphon Server to instance %p", syphonServer);
            mSyphonServerParentInstance = syphonServer;
        }
        
		mSuites.TimeSuite->GetTicksPerSecond(&mTicksPerSecond);
//		for (int i = 0; i < AUDIO_BUFFER_MAX_CHANNELS; i++)
//		{
//			mAudioBuffers[i] = new float[AUDIO_BUFFER_SIZE];
//		}

		NSLog(		@"Clocks per second: %i.",
					CLOCKS_PER_SEC);
        }



	/* Shutdown is handled here.
	**
	*/
	TransmitInstance::~TransmitInstance()
	{
		// Be a good citizen and dispose of any memory used
//		for (int i = 0; i < AUDIO_BUFFER_MAX_CHANNELS; i++)
//		{
//			delete(mAudioBuffers[i]);
//        }
    }

	/*
	**
	*/
//	tmResult TransmitInstance::QueryAudioMode(
//		const tmStdParms* inStdParms,
//		const tmInstance* inInstance,
//		csSDK_int32 inQueryIterationIndex,
//		tmAudioMode* outAudioMode)
//	{
//		outAudioMode->outNumChannels = 2;
//		outAudioMode->outAudioSampleRate = 48000;
//		outAudioMode->outMaxBufferSize = 48000;
//		outAudioMode->outChannelLabels[0] = kPrAudioChannelLabel_FrontLeft;
//		outAudioMode->outChannelLabels[1] = kPrAudioChannelLabel_FrontRight;
//		outAudioMode->outLatency = inInstance->inVideoFrameRate * 5; // Ask for 5 video frames preroll
//		return tmResult_Success;
//	}

	/* We're not picky.  We claim to support any format the host can throw at us (yeah right).
	**
	*/
	tmResult TransmitInstance::QueryVideoMode(
		const tmStdParms* inStdParms,
		const tmInstance* inInstance,
		csSDK_int32 inQueryIterationIndex,
		tmVideoMode* outVideoMode)
	{
		outVideoMode->outWidth = 0;
		outVideoMode->outHeight = 0;
		outVideoMode->outPARNum = 0;
		outVideoMode->outPARDen = 0;
		outVideoMode->outFieldType = prFieldsNone;
        outVideoMode->outPixelFormat =  PrPixelFormat_BGRA_4444_8u;//PrPixelFormat_Any;// PrPixelFormat_BGRA_4444_8u; // or PrPixelFormat_ARGB_4444_8u
        outVideoMode->outLatency = inInstance->inVideoFrameRate * 1; // Ask for 5 frames preroll

        
		mVideoFrameRate = inInstance->inVideoFrameRate;

		return tmResult_Success;
	}

	/*
	**
	*/
	tmResult TransmitInstance::ActivateDeactivate(
		const tmStdParms* inStdParms,
		const tmInstance* inInstance,
		PrActivationEvent inActivationEvent,
		prBool inAudioActive,
		prBool inVideoActive)
	{
		NSLog(@"ActivateDeactivate called.");

		if (inAudioActive || inVideoActive)
		{
		//	mDevice->StartTransmit();
			if (inAudioActive && inVideoActive)
				NSLog(@"with audio active and video active.");
			else if (inAudioActive)
				NSLog(@"with audio active.");
			else
				NSLog(@"with video active.");			
		}
		else
		{
		//	mDevice->StopTransmit();
			NSLog(@"to deactivate.");
		}

		return tmResult_Success;
	}
	
	/*
	**
	*/
	tmResult TransmitInstance::StartPlaybackClock(
		const tmStdParms* inStdParms,
		const tmInstance* inInstance,
		const tmPlaybackClock* inClock)
	{
		float			frameTimeInSeconds	= 0;

		mClockCallback				= inClock->inClockCallback;
		mCallbackContext			= inClock->inCallbackContext;
		mPlaybackSpeed				= inClock->inSpeed;
		mUpdateClockRegistration	= 0;

		frameTimeInSeconds = (float) inClock->inStartTime / mTicksPerSecond;


		if (inClock->inPlayMode == playmode_Scrubbing)
		{
			NSLog(@"StartPlaybackClock called for time %7.2f. Scrubbing.", frameTimeInSeconds);
		}
		else if (inClock->inPlayMode == playmode_Playing)
		{
			NSLog(@"StartPlaybackClock called for time %7.2f. Playing.", frameTimeInSeconds);
		}

		// If not yet playing, and called to play,
		// then register our UpdateClock function that calls the audio callback asynchronously during playback
		// Note that StartPlaybackClock can be called multiple times without a StopPlaybackClock,
		// for example if changing playback speed in the timeline.
		// If already playing, we the callbackContext doesn't change, and we let the current clock continue.
		if (!mPlaying && inClock->inPlayMode == playmode_Playing)
		{
			mPlaying = kPrTrue;

			// Initialize the ClockInstanceData that the UpdateClock function will need
			// We allocate the data here, and the data will be disposed at the end of the UpdateClock function
			ClockInstanceData *instanceData = new ClockInstanceData;
			instanceData->startTime = inClock->inStartTime;
			instanceData->callbackContextPtr = &mCallbackContext;
			instanceData->clockCallback = mClockCallback;
			instanceData->ticksPerSecond = mTicksPerSecond;
			instanceData->videoFrameRate = mVideoFrameRate;
			instanceData->playID = inInstance->inPlayID;
//			instanceData->audioBuffers = mAudioBuffers;
//			instanceData->audioSampleRate = inInstance->inAudioSampleRate;
			instanceData->suites = mSuites;

			// Cross-platform threading suites!
			mSuites.ThreadedWorkSuite->RegisterForThreadedWork(	&UpdateClock,
																instanceData,
																&mUpdateClockRegistration);
			mSuites.ThreadedWorkSuite->QueueThreadedWork(mUpdateClockRegistration, inInstance->inInstanceID);
		}

		return tmResult_Success;
	}

	/*
	**
	*/
	tmResult TransmitInstance::StopPlaybackClock(
		const tmStdParms* inStdParms,
		const tmInstance* inInstance)
	{
		mClockCallback = 0;
		mCallbackContext = 0;
		mPlaying = kPrFalse;

		if (mUpdateClockRegistration)
		{
			mSuites.ThreadedWorkSuite->UnregisterForThreadedWork(mUpdateClockRegistration);
			mUpdateClockRegistration = 0;
		}

		NSLog(@"StopPlaybackClock called.");

		return tmResult_Success;
	}

	/*
	**
	*/
	tmResult TransmitInstance::PushVideo(
		const tmStdParms* inStdParms,
		const tmInstance* inInstance,
		const tmPushVideo* inPushVideo)
	{
		// Send the video frames to the hardware.  We also log frame info to the debug console.
		float			frameTimeInSeconds	= 0;
		prRect			frameBounds;
		csSDK_uint32	parNum				= 0,
						parDen				= 0;
		PrPixelFormat	pixelFormat			= PrPixelFormat_Invalid;
//		int				audioSampleCount = 0;
//		prSuiteError	returnValue			= 0;

		frameTimeInSeconds = (float) inPushVideo->inTime / mTicksPerSecond;
		mSuites.PPixSuite->GetBounds(inPushVideo->inFrames[0].inFrame, &frameBounds);
		mSuites.PPixSuite->GetPixelAspectRatio(inPushVideo->inFrames[0].inFrame, &parNum, &parDen);
		mSuites.PPixSuite->GetPixelFormat(inPushVideo->inFrames[0].inFrame, &pixelFormat);
		
        char* pixels = NULL;
        mSuites.PPixSuite->GetPixels(inPushVideo->inFrames[0].inFrame,
                                     PrPPixBufferAccess_ReadOnly,
                                     &pixels);
        
        @autoreleasepool
        {
            // bind our syphon GL Context
            CGLSetCurrentContext(mSyphonServerParentInstance.context);

            NSRect syphonRect = NSMakeRect(0, 0, abs(frameBounds.right - frameBounds.left), abs(frameBounds.top - frameBounds.bottom));
            
            // Upload the contents of the frame to opengl here.
            GLuint texture = 0;
            glGenTextures(1, &texture);
            glEnable(GL_TEXTURE_RECTANGLE_EXT);
            glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texture);
            
            glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, 1);
            glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
            glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, syphonRect.size.width, syphonRect.size.height, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, pixels);
            
            [mSyphonServerParentInstance publishFrameTexture:texture textureTarget:GL_TEXTURE_RECTANGLE_EXT imageRegion:syphonRect textureDimensions:syphonRect.size flipped:NO];
            
        
            glDeleteTextures(1, &texture);
        }
//		NSLog(@"PushVideo called for time %7.2f, frame size: %d x %d, PAR: %4.3f, pixel format: %#x.",
//			  frameTimeInSeconds,
//			  abs(frameBounds.right - frameBounds.left),
//			  abs(frameBounds.top - frameBounds.bottom),
//			  (float) parNum / parDen,
//			  pixelFormat);
		
		//
		// This is where a transmit plug-in could queue up the frame to an actual hardware device.
		//

		// Call this only during scrubbing, or during preroll to get audio for the preroll frames.
		// The rest of the audio during playback should be requested in our clock callback: UpdateClock()
		if (inPushVideo->inPlayMode == playmode_Scrubbing ||
			(inPushVideo->inPlayMode == playmode_Playing && !mPlaying))
		{
//			// How many audio samples shall we request?  Calculate the number of audio samples in one frame
//			audioSampleCount = (int) (inInstance->inAudioSampleRate * mVideoFrameRate / mTicksPerSecond);
//			if (audioSampleCount > AUDIO_BUFFER_SIZE)
//			{
//				// If we get here, we underestimated the size of the audio buffer, and may need to adjust it higher
//				NSLog(@"AUDIO_BUFFER_SIZE too small.");
//
//				audioSampleCount = AUDIO_BUFFER_SIZE;
//			}
//
//			// Request the audio!  But... we don't do anything with it for now.  At least we know if it's valid.
//			returnValue = mSuites.PlayModuleAudioSuite->GetNextAudioBuffer(inInstance->inPlayID, 0, (float **)mAudioBuffers, audioSampleCount);
		}
		
		// Dispose of the PPix(es) when done!
		for (int i=0; i< inPushVideo->inFrameCount; i++)
		{
			mSuites.PPixSuite->Dispose(inPushVideo->inFrames[i].inFrame);
		}

		return tmResult_Success;
	}


////
//// TransmitPlugin methods
////

	/* Startup is handled here.
	**
	*/
	TransmitPlugin::TransmitPlugin(
		tmStdParms* ioStdParms,
		tmPluginInfo* outPluginInfo)
	{
		// Here, you could make sure hardware is available

		copyConvertStringLiteralIntoUTF16(PLUGIN_DISPLAY_NAME, outPluginInfo->outDisplayName);
		
		outPluginInfo->outAudioAvailable = kPrFalse;
		outPluginInfo->outAudioDefaultEnabled = kPrFalse;
		outPluginInfo->outClockAvailable = kPrFalse;	// Set this to kPrFalse if the transmitter handles video only
		outPluginInfo->outVideoAvailable = kPrTrue;
		outPluginInfo->outVideoDefaultEnabled = kPrTrue;
		outPluginInfo->outHasSetup = kPrFalse;

		// Acquire any suites needed!
		mSuites.SPBasic = ioStdParms->piSuites->utilFuncs->getSPBasicSuite();
//		mSuites.SPBasic->AcquireSuite(kPrSDKPlayModuleAudioSuite, kPrSDKPlayModuleAudioSuiteVersion, const_cast<const void**>(reinterpret_cast<void**>(&mSuites.PlayModuleAudioSuite)));
		mSuites.SPBasic->AcquireSuite(kPrSDKPPixSuite, kPrSDKPPixSuiteVersion, const_cast<const void**>(reinterpret_cast<void**>(&mSuites.PPixSuite)));
		mSuites.SPBasic->AcquireSuite(kPrSDKThreadedWorkSuite, kPrSDKThreadedWorkSuiteVersion3, const_cast<const void**>(reinterpret_cast<void**>(&mSuites.ThreadedWorkSuite)));
		mSuites.SPBasic->AcquireSuite(kPrSDKTimeSuite, kPrSDKTimeSuiteVersion, const_cast<const void**>(reinterpret_cast<void**>(&mSuites.TimeSuite)));
        
        @autoreleasepool
        {
            CGLPixelFormatObj mPxlFmt = NULL;
            CGLPixelFormatAttribute attribs[] = {kCGLPFAAccelerated, kCGLPFANoRecovery, (CGLPixelFormatAttribute)NULL};
            
            CGLError err = kCGLNoError;
            GLint numPixelFormats = 0;
            
            err = CGLChoosePixelFormat(attribs, &mPxlFmt, &numPixelFormats);
            
            if(err != kCGLNoError)
            {
                NSLog(@"Error choosing pixel format %s", CGLErrorString(err));
            }
            
            err = CGLCreateContext(mPxlFmt, NULL, &mCGLContext);
            
            if(err != kCGLNoError)
            {
                NSLog(@"Error creating context %s", CGLErrorString(err));
            }
            
            if(mCGLContext)
            {
                mSyphonServer = [[SyphonServer alloc] initWithName:@"Syphon Transmitter Out" context:mCGLContext options:nil];
                
                NSLog(@"Initting Syphon Server %@,  for instance %p", mSyphonServer, this);
            }
        }

	}

	/* Shutdown is handled here.
	**
	*/
	TransmitPlugin::~TransmitPlugin()
	{
		// Be a good citizen and dispose of any suites used
//		mSuites.SPBasic->ReleaseSuite(kPrSDKPlayModuleAudioSuite, kPrSDKPlayModuleAudioSuiteVersion);
		mSuites.SPBasic->ReleaseSuite(kPrSDKPPixSuite, kPrSDKPPixSuiteVersion);
		mSuites.SPBasic->ReleaseSuite(kPrSDKThreadedWorkSuite, kPrSDKThreadedWorkSuiteVersion3);
		mSuites.SPBasic->ReleaseSuite(kPrSDKTimeSuite, kPrSDKTimeSuiteVersion);
        
        @autoreleasepool
        {
            if(mSyphonServer)
            {
                NSLog(@"Releasing Syphon Server %@,  for instance %p", mSyphonServer, this);
                [mSyphonServer stop];
                mSyphonServer = nil;
            }
            if(mCGLContext)
            {
                CGLReleaseContext(mCGLContext);
                mCGLContext = NULL;
            }
        }

	}

	/*
	**
	*/
	tmResult TransmitPlugin::SetupDialog(
		tmStdParms* ioStdParms,
		prParentWnd inParentWnd)
	{
		// Get the settings, display a modal setup dialog for the user
		// MessageBox()

		// If the user changed the settings, save the new settings back to
		// ioStdParms->ioSerializedPluginData, and update ioStdParms->ioSerializedPluginDataSize

		return tmResult_Success;
	}
	
	/*
	**
	*/
	tmResult TransmitPlugin::NeedsReset(
		const tmStdParms* inStdParms,
		prBool* outResetModule)
	{
        NSLog(@"Reset Plugin");
		// Did the hardware change?
		// if (it did)
		//{
		//	*outResetModule = kPrTrue;
		//}
		return tmResult_Success;
	}
	
	/*
	**
	*/
	void* TransmitPlugin::CreateInstance(
		const tmStdParms* inStdParms,
		tmInstance* inInstance)
	{
		return new TransmitInstance(inInstance, mDevice, mSettings, mSuites, mSyphonServer);
	}

	void TransmitPlugin::DisposeInstance(
		const tmStdParms* inStdParms,
		tmInstance* inInstance)
	{
		delete (TransmitInstance*)inInstance->ioPrivateInstanceData;
	}
