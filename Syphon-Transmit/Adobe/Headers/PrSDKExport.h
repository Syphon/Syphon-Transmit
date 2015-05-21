/*******************************************************************/
/*                                                                 */
/*                      ADOBE CONFIDENTIAL                         */
/*                   _ _ _ _ _ _ _ _ _ _ _ _ _                     */
/*                                                                 */
/* Copyright 2007 Adobe Systems Incorporated                       */
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

/*		
	MediaCore Movie Exporter API.
*/

#ifndef	PRSDKEXPORT_H
#define PRSDKEXPORT_H

#ifndef PRSDKTYPES_H
#include "PrSDKTypes.h"
#endif

#ifndef PRSDKENTRY_H
#include "PrSDKEntry.h"
#endif

#ifndef PRSDKQUALITY_H
#include "PrSDKQuality.h"
#endif

#ifndef PRSDKTIMESUITE_H
#include "PrSDKTimeSuite.h"
#endif

#ifndef PRSDKRENDERCACHETYPE_H
#include "PrSDKRenderCacheType.h"
#endif

#ifndef PRSDKPIXELFORMAT_H
#include "PrSDKPixelFormat.h"
#endif

#ifndef __SPBasic__
#include "SPBasic.h"
#endif

#ifndef PRSDKAUDIOSUITE_H
#include "PrSDKAudioSuite.h"
#endif

#pragma pack(push, 1)

#ifdef __cplusplus
extern "C" {
#endif

// ParameterIdentifier. Non-localized, unique string. 
// !!! NOTE: This identifier must be unique inside a multigroup. !!!
typedef char	exParamIdentifier[256];

#define prExportVersion100		1					// 9.00
#define prExportVersion101		2					// 9.0.1
#define prExportVersion200		3					// CS5
#define prExportVersion250		4					// CS5.5
#define prExportVersion300		5					// CS6
#define prExportVersion400		6					// CS7
#define EXPORTMOD_VERSION		prExportVersion400	// current version

// filled in during exSelStartup. Added in CS6, this is also passed to exSelShutdown.
typedef struct
{
	csSDK_uint32		unused;				// obsolete
	csSDK_uint32		fileType;			// unique identifier per exporter instance -- 
											// use this if plug-in appears as multiple exporters to host,
											// see note below for exportReqIndex.
	prUTF16Char			fileTypeName[256];
	prUTF16Char			fileTypeDefaultExtension[256];	// default export extension. Can superceded by exSelQueryExportFileExtension
	csSDK_uint32		classID;			// The classID for the module
											// This is used to differentiate between export modules that
											// support the same fileType and to cross reference between
											// different plugin types (i.e. play and record modules).
	csSDK_int32			exportReqIndex;		// Used for iterating exporters:
											//
											// The exporter returns exportReturn_IterateExporter from the first exSelStartup
											// message to indicate there are more exporter, and 
											// exportReturn_IterateExporterDone after the final exporter is identified.
											//
											// The exporterReqIndex begins at zero and is incremented 
											// on each call to indicate the current request ordinal.

	csSDK_int32			wantsNoProgressBar;	// Exporter wants to show its own progress dialog; do not show the default
											// progress dialog during a export. The compiler will NOT get exportReturn_Abort
											// errors from the host during callbacks, and must detect an abort on its
											// own, and return exportReturn_Abort from exSelExport if the user aborts export.
	csSDK_int32			hideInUI;			// This exporter is for making preview files only, and should not be visible
											// in the application UI.

	csSDK_int32			doesNotSupportAudioOnly;	// AV exporter can only export video or video and audio, not audio only

	// info/capabilities
	csSDK_int32			canExportVideo;
	csSDK_int32			canExportAudio;
	csSDK_int32			singleFrameOnly;	// exporter does stills only.
											// host may handle video export as n or more exported files
	csSDK_int32			maxAudiences;
	csSDK_int32			interfaceVersion;	// version of API that this plugin was written against. Use EXPORTMOD_VERSION in current sdk header
	csSDK_uint32		isCacheable;		// added in CS5
	csSDK_uint32		canConformToMatchParams; // CS 7 [TODO] explanation to be provided
	csSDK_uint32		canEmbedCaptions; // CS 7 [TODO] explanation to be provided
} exExporterInfoRec;

// sent during exSelBeginInstance/exSelEndInstance
typedef struct
{
	csSDK_uint32	exporterPluginID;		// use with exporter suites
	csSDK_uint32	fileType;				// unique identifier per 'exporter'
	void*	privateData;
} exExporterInstanceRec;

// filled in during exSelExport
typedef struct
{
	csSDK_uint32	exporterPluginID;			// use with exporter suites
	void*			privateData;				// created during exSelBeginInstance
	csSDK_uint32	fileType;					// unique identifier per 'exporter'
	csSDK_int32		exportAudio;				// export audio or video may have changed, always check
	csSDK_int32		exportVideo;
	PrTime			startTime;					// time location to start request from render suites
	PrTime			endTime;					// end of time to export
	csSDK_uint32	fileObject;					// use with PrSDKExportFileSuite
	PrTimelineID	timelineData;				// timeline callback suites
	csSDK_int32		reserveMetaDataSpace;		// amount to reserve in a file for meta data storage
	csSDK_int32		maximumRenderQuality;		// if non-0, render at highest possible quality
	csSDK_int32		embedCaptions;				// if non-0, embed captions obtained from PrSDKCaptioningSuite. exExporterInfoRec.canEmbedCaptions must be set at init time for this to activate.
} exDoExportRec;

// sent during exSelValidateParamChanged
typedef struct
{
	csSDK_uint32				exporterPluginID;
	void*						privateData;			// created during exSelBeginInstance
	csSDK_uint32				fileType;				// unique identifier per 'exporter'
	csSDK_int32					exportAudio;			// export audio or video may have changed, always check
	csSDK_int32					exportVideo;
	csSDK_int32					multiGroupIndex;		// current param multigroup container
	exParamIdentifier			changedParamIdentifier;	// what param changed? 
														// NOTE: changedParamIdentifier may be empty if the changed item 
														// was exportAudio, exportVideo or the current multiGroupIndex
	csSDK_int32					rebuildAllParams;		// set true if host should reload ALL params from the param list
} exParamChangedRec;


// sent during exSelGenerateDefaultParams
typedef struct
{
	csSDK_uint32	exporterPluginID;
	void*			privateData;		// created during exSelBeginInstance
	csSDK_uint32	fileType;			// unique identifier per 'exporter'
} exGenerateDefaultParamRec;



// sent during exSelPostProcessParams
typedef struct
{
	csSDK_uint32	exporterPluginID;
	void*			privateData;		// created during exSelBeginInstance
	csSDK_uint32	fileType;			// unique identifier per 'exporter'
	csSDK_int32		exportAudio;		// export audio or video may have changed, always check
	csSDK_int32		exportVideo;
	csSDK_int32		doConformToMatchParams;	// [TODO] we need a big comment above that outlines how to use the 'match' params hierarchy
} exPostProcessParamsRec;


// Sent during exSelGetParamSummary
//
// The text labels are arbitrary, but exporters will generally generate
// text such as:
// "Video: 29.97 fps @ 720x480, someVideoCodec @ 5mbit 
// "Audio: Stereo 16bit 44.1khz someAudioCodec
//
// However, host UIs should generally permit any 3 short lines of text and
// leave adequate room to display them.
typedef struct
{
	csSDK_uint32	exporterPluginID;
	void*			privateData;		// created during exSelBeginInstance
	csSDK_int32		exportAudio;		// export audio or video may have changed, always check
	csSDK_int32		exportVideo;
	prUTF16Char		videoSummary[256];
	prUTF16Char		audioSummary[256];
	prUTF16Char		bitrateSummary[256];
} exParamSummaryRec;


// Sent during exSelParamButton
typedef struct
{
	csSDK_uint32		exporterPluginID;
	void*				privateData;		// created during exSelBeginInstance
	csSDK_uint32		fileType;			// unique identifier per 'exporter'
	csSDK_int32			exportAudio;		// export audio or video may have changed, always check
	csSDK_int32			exportVideo;
	csSDK_int32			multiGroupIndex;
	exParamIdentifier	buttonParamIdentifier;
} exParamButtonRec;


// Standard parms passed into xSDKExport
typedef SPBasicSuite* (*plugGetSPBasicSuiteFunc)();


typedef struct
{
	csSDK_int32					interfaceVer;	// version # of interface (currently EXPORTMOD_VERSION)
	plugGetSPBasicSuiteFunc		getSPBasicSuite;
} exportStdParms;



// sent during exSelQueryExportFileExtension
typedef struct
{
	csSDK_uint32				exporterPluginID;
	void*						privateData;			// created during exSelBeginInstance
	csSDK_uint32				fileType;				// unique identifier per 'exporter'
	prUTF16Char					outFileExtension[256];
} exQueryExportFileExtensionRec;

// embedded file element for exQueryOutputFileListAfterExportRec
typedef struct
{
	csSDK_int32			pathLength;
	prUTF16Char*		path;
} exOutputFileRec;


// sent during exSelQueryOutputFileList
// Calling sequence:
//	-- first call: 
//		the plug-in fills out 'numOutputFiles'
//  -- second call: 
//		the host makes numOutputFiles count of outputFileRecs, but empty. Plug-in
//		fills out the path length (incl trailing null) for each exOutputFileRec
//		element in outputFileRecs;
//	-- third call:
//		host has allocated all paths in each outputFileRec. Plug-in fills in the
//		path member of outputFileRec;
//
//	NOTE: the plug-in can fail exSelQueryOutputFileList by returning
//	exportReturn_Unsupported. The output file is then assumed to be the same
//	the one passed in exDoExportRec
typedef struct
{
	csSDK_uint32				exporterPluginID;
	void*						privateData;			// created during exSelBeginInstance
	csSDK_uint32				fileType;				// unique identifier per 'exporter'
	csSDK_uint32				numOutputFiles;
	PrSDKString					path;
	exOutputFileRec				*outputFileRecs;
} exQueryOutputFileListRec;


// sent during exSelQueryStillSequence
typedef struct
{
	csSDK_uint32				exporterPluginID;
	void*						privateData;			// created during exSelBeginInstance
	csSDK_uint32				fileType;				// unique identifier per 'exporter'
	csSDK_int32					exportAsStillSequence;
	PrTime						exportFrameRate;
} exQueryStillSequenceRec;

// sent during exSelQueryOutputSettings;
typedef struct
{
	csSDK_uint32		exporterPluginID;
	void*				privateData;			// created during exSelBeginInstance
	csSDK_uint32		fileType;				// unique identifier per 'exporter'
	csSDK_int32			inMultiGroupIndex;
	csSDK_int32			inExportVideo;
	csSDK_int32			inExportAudio;
	csSDK_int32			outVideoWidth;
	csSDK_int32			outVideoHeight;
	PrTime				outVideoFrameRate;
	csSDK_int32			outVideoAspectNum;
	csSDK_int32			outVideoAspectDen;
	csSDK_int32			outVideoFieldType;			// prFieldsNone, prFieldsUpperFirst, prFieldsLowerFirst
	double				outAudioSampleRate;
	PrAudioSampleType	outAudioSampleType;
	PrAudioChannelType	outAudioChannelType;
	csSDK_uint32		outBitratePerSecond;
	csSDK_int32			outUseMaximumRenderPrecision; //Added in CS6
} exQueryOutputSettingsRec;


// sent during exSelValidateOutputSettings
typedef struct  
{
	csSDK_uint32				exporterPluginID;
	void*						privateData;			// created during exSelBeginInstance
	csSDK_uint32				fileType;				// unique identifier per 'exporter'
} exValidateOutputSettingsRec;


// Main entry prototype. Must be named "xSDKExport"
// ("xExport" was used by some legacy Premiere plug-ins, and is a deprecated named entry point)
typedef PREMPLUGENTRY (* ExportEntryFunc)(csSDK_int32 selector, exportStdParms *stdparms, void* param1, void* param2);
#define SDKExportEntryPointName		"xSDKExport"


// Selectors 
enum PrExportSelector
{
	exSelStartup,								// fill exExporterInfoRec
	exSelShutdown,								// pro forma: plug-in should release and be ready for app shutdown. 
	exSelBeginInstance,							// make private data. Persistent until exSelEndInstance is called.
	exSelGenerateDefaultParams,					// generate a default set of params
	exSelPostProcessParams,						// validate params from preset/disk. Fill all localized param names, load all constrained value pairs
	exSelValidateParamChanged,					// validate 1 param changed. Exporter should hide/dim/change any settings
												// related to this one param using the ExportParamSuite, e.g. dimming a control when a
												// related checkbox is checked/unchecked
	exSelGetParamSummary,						// generate export text summary description
	exSelParamButton,							// respond to a paramButton. generate opaque param info
	exSelEndInstance,							// 
	exSelExport,								// export!
	exSelQueryExportFileExtension,
	exSelQueryOutputFileList,
	exSelQueryStillSequence,					// ask a still-only exporter if it wants to export 
												// as a sequence, and at what frame rate.
	exSelQueryOutputSettings,					// query the exporter for general details about the current settings. This is a required selector.
	exSelValidateOutputSettings					// ask the exporter if it can export with the current settings.
												// exporter should return exportReturn_ErrLastErrorSet if not, and the error string
												// should be set to a description of the failure.
};


// return codes
// TODO -- most of these are copies from compiler header
enum PrExportReturnValue
{
	exportReturn_ErrNone = 0,			// no error
	exportReturn_Abort,					// User aborted the compile
	exportReturn_Done,					// Export finished normally
	exportReturn_InternalError,
	exportReturn_OutOfDiskSpace,		// Out of disk space error
	exportReturn_BufferFull,			// The offset into the audio buffer would overflow it
	exportReturn_ErrOther,				// 
	exportReturn_ErrMemory,				// ran out of memory
	exportReturn_ErrFileNotFound,		// File not found
	exportReturn_ErrTooManyOpenFiles,	// Too many open files
	exportReturn_ErrPermErr,			// Permission violation
	exportReturn_ErrOpenErr,			// Unable to open the file
	exportReturn_ErrInvalidDrive,		// Drive isn't valid.
	exportReturn_ErrDupFile,			// Duplicate Filename
	exportReturn_ErrIo,					// File io error
	exportReturn_ErrInUse,				// File is in use
	exportReturn_IterateExporter,       // Return value from exSelStartup to request Exporter iteration
	exportReturn_IterateExporterDone,   // Return value from exSelStartup to indicate there are no more Exporters
	exportReturn_InternalErrorSilent,	/*	Silent error code; host application will not display an error message on screen.
											Exporters can return this error code from compDoCompile if they wish to
											put their own customized error message on screen just before returning 
											control.  */
	exportReturn_ErrCodecBadInput,		// a video codec refused the input format
	exportReturn_ErrLastErrorSet,		// the Exporter had an error and set a display string for it using the PrSDKErrorSuite.
	exportReturn_ErrLastWarningSet,		// the Exporter had an warning and set a display string for it using the PrSDKErrorSuite.
	exportReturn_ErrLastInfoSet,		// the Exporter has an info string to display and set it using the PrSDKErrorSuite.
	exportReturn_ErrExceedsMaxFormatDuration, // the Exporter (or the host) has deemed the duration of the compile to be too large
	exportReturn_VideoCodecNeedsActivation,		// the current video codec is not activated and cannot be used.
	exportReturn_AudioCodecNeedsActivation,		// the current audio codec is not activated and cannot be used.
	exportReturn_IncompatibleAudioChannelType,	// the requested audio channels are not compatible with the source audio
	exportReturn_IncompatibleVideoCodec, //User tried to load a preset with Invalid Video codec
	exportReturn_IncompatibleAudioCodec, //User tried to load a preset with Invalid Audio codec
	exportReturn_ParamButtonCancel,		// User cancelled settings dialog by pressing cancel button
	exportReturn_Unsupported = -100		// Unsupported selector

};

#ifdef __cplusplus
}
#endif

#pragma pack(pop)

#endif // PRSDKEXPORT_H