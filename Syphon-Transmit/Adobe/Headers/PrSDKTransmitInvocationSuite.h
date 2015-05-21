/*******************************************************************/
/*                                                                 */
/*                      ADOBE CONFIDENTIAL                         */
/*                   _ _ _ _ _ _ _ _ _ _ _ _ _                     */
/*                                                                 */
/* Copyright 2011 Adobe Systems Incorporated                       */
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



//	This file is part of the public Premiere SDK.




#ifndef PRSDKTRANSMITINVOCATIONSUITE_H
#define PRSDKTRANSMITINVOCATIONSUITE_H


#include "PrSDKTransmit.h"


#pragma pack(push, 1)
#ifdef __cplusplus
extern "C" {
#endif


typedef void (*PrSDKTransmitChangedProc)(void* inTransmitChangedContext);



/**
**	Simple suite to push audio & video to active transmit plugins
**	Host will conform audio & video to the needs of the plugins
*/
#define kPrSDKTransmitInvocationSuite			"MediaCore Transmit Invocation Suite"
#define kPrSDKTransmitInvocationSuiteVersion	1

/**
**	IDs of adobe provided transmit plugins.
*/
#define PrTransmitDesktopAudioPluginID			"1A3A1D9F-772F-49EF-8850-402B885EF68C"
#define PrTransmitDVPluginID					"CA1A71F1-5D7F-454D-9594-5117F50E2CD3"
#define PrTransmitFullScreenPluginID			"D40EB215-EBE2-4E89-9D60-B7375F14A02D"

typedef struct 
{
	/**
	**	Fill in video & audio properties, leave other values as 0.
	**	Will return an error if no active transmit plugins.
	*/
	tmResult (*CreateInstance)(
		tmInstance* ioInstance,
		PrSDKTransmitChangedProc inTransmitChangedProc,
		void* inTransmitChangedContext);
	tmResult (*DisposeInstance)(
		tmInstance* ioInstance);

	/**
	**	Push media to active transmit plugins
	*/
	tmResult (*HasVideoDevice)(
		const tmInstance* inInstance,
		prBool* outHasVideo);
	tmResult (*PushVideo)(
		const tmInstance* inInstance,
		const tmPushVideo* inPushVideo);

} PrSDKTransmitInvocationSuite;




#ifdef __cplusplus
}
#endif
#pragma pack(pop)



#endif