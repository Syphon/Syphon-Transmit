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

#include <PrSDKTransmit.h>
#include <PrSDKPlayModuleAudioSuite.h>
#include <PrSDKPPixSuite.h>
#include <PrSDKThreadedWorkSuite.h>
#include "SDK_File.h"
#ifdef PRWIN_ENV
#include <ctime>
#endif

#import <Syphon/Syphon.h>
#import <Metal/Metal.h>
//#import <OpenGL/OpenGL.h>
//#include <OpenGL/gl.h>

#define	PLUGIN_DISPLAY_NAME	L"Syphon Server Transmitter"

typedef struct
{
	csSDK_int32 mVersion;
} SDKSettings;

typedef struct
{
	csSDK_int32 mVersion;
} SDKDevicePtr;

typedef struct
{
	SPBasicSuite*					SPBasic;
	PrSDKPlayModuleAudioSuite*		PlayModuleAudioSuite;
	PrSDKPPixSuite*					PPixSuite;
	PrSDKThreadedWorkSuiteVersion3*	ThreadedWorkSuite;
	PrSDKTimeSuite*					TimeSuite;
} SDKSuites;


namespace SDK
{

/* The TransmitInstance class is called by the TransmitModule and the TransmitPlugin to handle many calls from the transmit host.
** There can be several instances outstanding at any given time.
*/
class SyphonTransmitInstance
{
public:
	SyphonTransmitInstance(
		const tmInstance* inInstance,
		const SDKDevicePtr& inDevice,
		const SDKSettings& inSettings,
		const SDKSuites& inSuites,
       SyphonMetalServer* syphonServer,
       id<MTLCommandQueue> commandQueue);

	~SyphonTransmitInstance();

    tmResult QueryVideoMode(
		const tmStdParms* inStdParms,
		const tmInstance* inInstance,
		csSDK_int32 inQueryIterationIndex,
		tmVideoMode* outVideoMode);

	tmResult ActivateDeactivate(
		const tmStdParms* inStdParms,
		const tmInstance* inInstance,
		PrActivationEvent inActivationEvent,
		prBool inAudioActive,
		prBool inVideoActive);

	tmResult StartPlaybackClock(
		const tmStdParms* inStdParms,
		const tmInstance* inInstance,
		const tmPlaybackClock* inClock);

	tmResult StopPlaybackClock(
		const tmStdParms* inStdParms,
		const tmInstance* inInstance);

	tmResult PushVideo(
		const tmStdParms* inStdParms,
		const tmInstance* inInstance,
		const tmPushVideo* inPushVideo);

private:
	// These members immediately below (before the empty line) all get initialized by being passed in from the TransmitPlugin
	SDKDevicePtr				mDevice;
	SDKSettings					mSettings;
	SDKSuites					mSuites;

	PrTime						mTicksPerSecond;
	PrTime						mVideoFrameRate;

	tmClockCallback				mClockCallback;
	void *						mCallbackContext;
	ThreadedWorkRegistration	mUpdateClockRegistration;

	float						mPlaybackSpeed;
	prBool						mPlaying;
    
    // Our Syphon Server is passed in from our Plugin below during instantiation
    // We only use it to publish frames, so we dont do anything like dealloc it, etc.
    id<MTLCommandQueue> mParentCommandQueue;
    SyphonMetalServer* mSyphonServerParentInstance;
};


/* The TransmitPlugin class is called by the TransmitModule to handle many calls from the transmit host.
** It also handles creation and cleanup of TransmitInstances.
** There could concievably be multiple plugins in a single module, although we only implement one here.
*/
class SyphonTransmitPlugin
{
public:
	SyphonTransmitPlugin(
		tmStdParms* ioStdParms,
		tmPluginInfo* outPluginInfo);

	~SyphonTransmitPlugin();

	tmResult SetupDialog(
		tmStdParms* ioStdParms,
		prParentWnd inParentWnd);

	tmResult NeedsReset(
		const tmStdParms* inStdParms,
		prBool* outResetModule);

	void* CreateInstance(
		const tmStdParms* inStdParms,
		tmInstance* inInstance);

	void DisposeInstance(
		const tmStdParms* inStdParms,
		tmInstance* inInstance);

    id<MTLCommandQueue> mCommandQueue;
    SyphonMetalServer* mSyphonServer;

private:
	SDKDevicePtr	mDevice;
	SDKSettings		mSettings;
	SDKSuites		mSuites;
};

}; // namespace SDK
