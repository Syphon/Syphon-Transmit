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

			clockInstanceData->clockCallback(*clockInstanceData->callbackContextPtr, timeElapsed);

			// Sleep for a frame's length
			// Try sleeping for the half the time, since Mac OS seems to oversleep :)
            usleep(timeBetweenClockUpdates / 2);
		}

		NSLog(		@"Clock with callback context %llx exited.",
					(long long)*clockInstanceData->callbackContextPtr);

		delete(clockInstanceData);
	}

#pragma mark - Instance Methods

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
        }

#pragma mark -

	TransmitInstance::~TransmitInstance()
	{
        // TODO: Do we want to nil our syphon handle here?
        // Does that fuck with retain count / release ?
    }


#pragma mark - Query Video Mode

/* We're not picky.  We claim to support any format the host can throw at us (yeah right). */
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

#pragma mark - Activate/Deactivate

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
	
#pragma mark - Start Clock

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
			instanceData->suites = mSuites;

			// Cross-platform threading suites!
			mSuites.ThreadedWorkSuite->RegisterForThreadedWork(	&UpdateClock,
																instanceData,
																&mUpdateClockRegistration);
			mSuites.ThreadedWorkSuite->QueueThreadedWork(mUpdateClockRegistration, inInstance->inInstanceID);
		}

		return tmResult_Success;
	}

#pragma mark - Stop Clock

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

#pragma mark - Push Video

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
            
            // TODO: use bind to draw frame of size / unbind
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
				
		// Dispose of the PPix(es) when done!
		for (int i=0; i< inPushVideo->inFrameCount; i++)
		{
			mSuites.PPixSuite->Dispose(inPushVideo->inFrames[i].inFrame);
		}

		return tmResult_Success;
	}

#pragma mark - Trasmit Plugin Methods

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

#pragma mark - Shutdown

	TransmitPlugin::~TransmitPlugin()
	{
		// Be a good citizen and dispose of any suites used
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

#pragma mark - Setup Dialog (N/A?)

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
	
#pragma mark - Reset

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
	
#pragma mark - Create

	void* TransmitPlugin::CreateInstance(
		const tmStdParms* inStdParms,
		tmInstance* inInstance)
	{
		return new TransmitInstance(inInstance, mDevice, mSettings, mSuites, mSyphonServer);
	}

#pragma mark - Dispose

	void TransmitPlugin::DisposeInstance(
		const tmStdParms* inStdParms,
		tmInstance* inInstance)
	{
		delete (TransmitInstance*)inInstance->ioPrivateInstanceData;
	}
