/*******************************************************************/
/*                                                                 */
/*                      ADOBE CONFIDENTIAL                         */
/*                   _ _ _ _ _ _ _ _ _ _ _ _ _                     */
/*                                                                 */
/* Copyright 2002 Adobe Systems Incorporated                       */
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

#ifndef PRSDKASYNCIMPORTER_H
#define PRSDKASYNCIMPORTER_H

#ifndef PRSDKTYPES_H
#include "PrSDKTypes.h"
#endif

#ifndef PRSDKTIMESUITE_H
#include "PrSDKTimeSuite.h"
#endif

#ifndef PRSDKENTRY_H
#include "PrSDKEntry.h"
#endif

#ifndef PRSDKIMPORTERSHARED_H
#include "PrSDKImporterShared.h"
#endif

#pragma pack(push, 1)

/**
**	An async importer is a mechanism (new in Pro 2.0) for the host to perform
**	input from a file in an asynchronous manner. It is a separate entry point
**	from a standard importer because it does not follow the same rules as an
**	importer.
**
**	All calls to AsyncImporterEntry are reentrant, except for the close 
**	selector. The close selector will only be called once, but may be called
**	while other calls are still executing. No calls will be made after the
**	close selector is called.
**
**	Here is an overview of the lifetime of an Async Importer:
**
**	1.) The host calls Open and GetInfo on the standard importer.
**	2.) The host calls imCreateAsyncImporter on the standard importer. At this
**		time, the standard importer creates the private data for the async
**		importer. The async importer MUST NOT contain a link to the standard
**		importer, as their lifetimes are now decoupled. The async importer, therefore,
**		must contain copies of all relevant private data from the creator
**		importer. The importer preferences are also guaranteed to not change
**		during the lifetime of the async importer.
**	3.)	The host uses the async importer to perform i/o.
**	4.) The host closes the async importer, forgetting about it. This will happen
**		whenever the app loses focus, or when the async importer is no longer
**		needed.
*/

typedef struct
{
	void*		inPrivateData;
	long				unused1;						//	Added in MediaCore CS3 to maintain struct alignment
	imSourceVideoRec	inSourceRec;
} aiAsyncRequest;

typedef PREMPLUGENTRY (*AsyncImporterEntry)(int inSelector, void* inParam);

//	Async Importer Selectors

enum
{
	aiInitiateAsyncRead,
	aiCancelAsyncRead,
	aiFlush,
	aiGetFrame,
	aiClose
};

//	Async Importer results

enum
{
	aiNoError,
	aiUnsupported,
	aiUnknownError,
	aiFrameNotFound
};

/**
Async Importer Selectors:

Message:	aiInitiateAsyncRead
Required:	yes
Purpose:	Called to start an asynchronous read for the specified frame. This call
			should return as quickly as possible without blocking. Note that no format
			for the frame is passed into this call, so the async importer should only
			do whatever is necessary to get the frame ready in memory. For example, disk
			i/o should definitely be scheduled. Decompression can also be scheduled, if
			the decompression does not depend on the output frame size and format. If it
			does, then decompression should be performed in aiGetFrame.
			
			inParam:	aiAsyncRequest*

Message:	aiCancelAsyncRead
Required:	no
Purpose:	Called to cancel an asynchronous read for the specified frame. This call is more
			along the lines of a hint, in that the async importer should only take what
			action is possible with this information. This call should not block.
			
			inParam:	aiAsyncRequest*

Message:	aiFlush
Required:	yes
Purpose:	Called to cancel all pending and executing requests. The async importer should
			block until all executing requests are completed or abandoned. No other calls will
			be made while aiFlush is occurring. aiFlush will always be called prior to
			aiClose.

			inParam:	inPrivateData

Message:	aiGetFrame
Required:	yes
Purpose:	Called to retrieve a frame which was previously scheduled using aiInitiateAsyncRead.
			This is usually simply a call to see if the frame is in the cache.
			
			inParam:	imGetSourceVideoRec*

Message:	aiClose
Required:	yes
Purpose:	Called to dispose of the async importer. It is appropriate for this call to block
			pending the completion of existing async operations.

			inParam:	inPrivateData

*/

#pragma pack(pop)


#endif