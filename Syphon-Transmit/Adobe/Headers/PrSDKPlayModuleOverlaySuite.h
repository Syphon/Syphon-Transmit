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


#ifndef PRSDKPLAYMODULEOVERLAYSUITESUITE_H
#define PRSDKPLAYMODULEOVERLAYSUITESUITE_H


#ifndef PRSDKTYPES_H
#include "PrSDKTypes.h"
#endif

#ifndef PRSDKMALERRORS_H
#include "PrSDKMALErrors.h"
#endif

#ifndef PRSDKPLAYMODULE_H
#include "PrSDKPlayModule.h"
#endif

#pragma pack(push, 1)

#ifdef __cplusplus
extern "C" {
#endif


#define kPrSDKPlayModuleOverlaySuite				"MediaCore Playmod Overlay Suite"
#define kPrSDKPlayModuleOverlaySuiteVersion			1


/**
**	If supported, set the player capability PMCapSupportsOverlayDrawing
*/
typedef struct
{
	/**
	**	Renders an overlay into the provided PPix.
	**		May only draw into opaque pixels unless inClearToTransparentBlack is specified.
	**		If a PPix is created, it will be cached under the key retrieved from GetIdentifier.
	**
	**	@param	inPlayID					Player module identifier
	**	@param	inTime						Requested overlay time
	**	@param	inLogicalRegion				Region of video segments being rendered
	**	@param	inDisplayWidth				Size of display
	**	@param	inDisplayHeight				Size of display
	**	@param	inClearToTransparentBlack	if kPrTrue the frame will first be cleared to transparent black before render
	**											This is useful if the composite will be of the whole frame instead of just
	**											the returned visible regions.
	**	@param	ioPPix						The frame into which to draw the overlay
	**											If NULL the host will allocate the PPix
	**											If provided PPix must be BGRA square pixel and sized to inDisplayWidth & inDisplayHeight
	*/
	prSuiteError (*RenderImage)(
		PrPlayID inPlayID,
		PrTime inTime,
		const prRect* inLogicalRegion,
		int inDisplayWidth,
		int inDisplayHeight,
		prBool inClearToTransparentBlack,
		PPixHand* ioPPix);

	/**
	**	Returns a unique identifier for the frame that would be produced with 
	**	the provided overlay parameters.
	**
	**	@param	inPlayID					Player module identifier
	**	@param	inTime						Requested overlay time
	**	@param	inLogicalRegion				Region of video segments being rendered
	**	@param	inDisplayWidth				Size of display
	**	@param	inDisplayHeight				Size of display
	**	@param	inClearToTransparentBlack	if kPrTrue the frame will first be cleared to transparent black before render
	**	@param	outIdentifier				Unique identifier for requested params
	*/
	prSuiteError (*GetIdentifier)(
		PrPlayID inPlayID,
		PrTime inTime,
		const prRect* inLogicalRegion,
		int inDisplayWidth,
		int inDisplayHeight,
		prBool inClearToTransparentBlack,
		prPluginID* outIdentifier);

	/**
	**	Returns if there are any regions visible for the current parameters.
	**
	**	@param	inPlayID					Player module identifier
	**	@param	inTime						Requested overlay time
	**	@param	inLogicalRegion				Region of video segments being rendered
	**	@param	inDisplayWidth				Size of display
	**	@param	inDisplayHeight				Size of display
	**	@param	outHasVisibleRegions		kPrTrue if the overlay varies is visible
	*/
	prSuiteError (*HasVisibleRegions)(
		PrPlayID inPlayID,
		PrTime inTime,
		const prRect* inLogicalRegion,
		int inDisplayWidth,
		int inDisplayHeight,
		prBool* outHasVisibleRegions);

	/**
	**	Returns the set of regions visible in display units for the current parameters.
	**	Set will be empty if no overlay exists.
	**
	**	@param	inPlayID					Player module identifier
	**	@param	inTime						Requested overlay time
	**	@param	inLogicalRegion				Region of video segments being rendered
	**	@param	inDisplayWidth				Size of display
	**	@param	inDisplayHeight				Size of display
	**	@param	outVisibleRegionArray		List of visible regions
	**	@param	ioVisibleRegionArrayCount	Count of visible regions.
	**											In value is size of outVisibleRegionArray
	**											Out value is available count of regions
	*/
	prSuiteError (*CalculateVisibleRegions)(
		PrPlayID inPlayID,
		PrTime inTime,
		const prRect* inLogicalRegion,
		int inDisplayWidth,
		int inDisplayHeight,
		prRect* outVisibleRegionArray,
		csSDK_int32* ioVisibleRegionArrayCount);

	/**
	**	Returns if the current overlay will vary over time
	**
	**	@param	inPlayID					Player module identifier
	**	@param	outVariesOverTime			kPrTrue if the overlay varies over time
	*/
	prSuiteError (*VariesOverTime)(
		PrPlayID inPlayID,
		prBool* outVariesOverTime);


} PrSDKPlayModuleOverlaySuite;



#ifdef __cplusplus
}
#endif

#pragma pack(pop)


#endif