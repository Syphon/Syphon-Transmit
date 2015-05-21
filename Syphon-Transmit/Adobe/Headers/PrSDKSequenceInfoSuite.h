/*******************************************************************/
/*                                                                 */
/*                      ADOBE CONFIDENTIAL                         */
/*                   _ _ _ _ _ _ _ _ _ _ _ _ _                     */
/*                                                                 */
/* Copyright 2009 Adobe Systems Incorporated                       */
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


#ifndef	PRSDKSEQUENCEINFOSUITE_H
#define PRSDKSEQUENCEINFOSUITE_H

#ifndef PRSDKTYPES_H
#include "PrSDKTypes.h"
#endif

#ifndef PRSDKMALERRORS_H
#include "PrSDKMALErrors.h"
#endif

#ifndef PRSDKTIMESUITE_H
#include "PrSDKTimeSuite.h"
#endif

#pragma pack(push, 1)

#ifdef __cplusplus
extern "C" {
#endif

#define kPrSDKSequenceInfoSuite				"MediaCore Sequence Info Suite"
#define kPrSDKSequenceInfoSuiteVersion		3

typedef struct 
{
	/**
	**	Get the video frame size of the sequence.
	**
	**	@param	inTimelineID	the timeline instance data
	**	@param	outFrameRect	on return, the size of the sequence video frame.
	*/
	prSuiteError (*GetFrameRect)(
		PrTimelineID inTimelineID, 
		prRect *outFrameRect);

	/**
	**	Get the aspect ratio of the sequence.
	**
	**	@param	inTimelineID	the timeline instance data
	**	@param	outNumerator	on return, the aspect ratio numerator.
	**	@param	outDenominator	on return, the aspect ratio denominator.
	*/
	prSuiteError (*GetPixelAspectRatio)(
		PrTimelineID inTimelineID,
		csSDK_uint32 *outNumerator,
		csSDK_uint32 *outDenominator);

	/**
	**	Get the framerate of the sequence.
	**
	**	@param	inTimelineID		the timeline instance data
	**	@param	outTicksPerFrame	the framerate in ticks.
	*/
	prSuiteError (*GetFrameRate)(
		PrTimelineID inTimelineID,
		PrTime* outTicksPerFrame);
	
	/**
	**	Get the field type of the sequence.
	**
	**	@param	inTimelineID		the timeline instance data
	**	@param	outFieldType		the field type.
	*/
	prSuiteError (*GetFieldType)(
		PrTimelineID inTimelineID,
		prFieldType* outFieldType);

	/**
	**	Get the zero point of the sequence.
	**
	**	@param	inTimelineID		the timeline instance data
	**	@param	outTicksPerFrame	start time of the sequence.
	*/
	prSuiteError (*GetZeroPoint)(
		PrTimelineID inTimelineID,
		PrTime* outTime);

	/**
	**	Returns if the sequence timecode is drop or non drop.
	**
	**	@param	inTimelineID		the timeline instance data
	**	@param	outDropFrame		if the sequence timecode is dropframe
	*/
	prSuiteError (*GetTimecodeDropFrame)(
		PrTimelineID inTimelineID,
		prBool* outDropFrame);


} PrSDKSequenceInfoSuite;

#ifdef __cplusplus
}
#endif

#pragma pack(pop)

#endif /* PRSDKSEQUENCEINFOSUITE_H */

