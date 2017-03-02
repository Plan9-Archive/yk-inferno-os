#define Cursor OSXCursor
#define Point OSXPoint
#define Rect OSXRect

#import <Cocoa/Cocoa.h>

#undef Cursor
#undef Point
#undef Rect
#undef nil

#include "dat.h"
#include "fns.h"
#include "screen-cocoa.h"

#include <draw.h>
#include <memdraw.h>
#include "cursor.h"
#include "keyboard.h"
#include "keycodes.h"

@interface Appwin : NSWindow @end
@interface Contentview : NSView @end

#define DBG

Memimage*	gscreen;
NSWindow*	win;
NSView*	view;
NSBitmapImageRep	*bits;
NSUInteger	wstyle = 0
	| NSTitledWindowMask
	| NSClosableWindowMask
	| NSMiniaturizableWindowMask
	| NSResizableWindowMask
	;

uchar*
attachscreen(Rectangle *screenr, ulong *chan, int *depth, int *width, int *softscreen)
{
	int xsz, ysz;
	NSRect r;

	memimageinit();

	r = [[NSScreen mainScreen] frame];
	r = [NSWindow contentRectForFrameRect:r styleMask:wstyle];

	win = [[Appwin alloc] initWithContentRect:r styleMask:wstyle backing:NSBackingStoreBuffered defer:NO];
	[win setTitle:@"emu"];
	[win center];
	[win setMinSize:NSMakeSize(160,100)];
	[win setPreservesContentDuringLiveResize:YES];
//	[win setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];

//	[win setDelegate:appsink];

	view = [[Contentview alloc] initWithFrame:r];
	[win setContentView:view];

	r = [view bounds];
	xsz = r.size.width;
	ysz = r.size.height;

	gscreen = allocmemimage(Rect(0,0,xsz,ysz), XBGR32);
	if(gscreen == nil)
		return nil;
	bits = [[NSBitmapImageRep alloc]
				initWithBitmapDataPlanes:&gscreen->data->bdata
				pixelsWide:Dx(gscreen->r)
				pixelsHigh:Dy(gscreen->r)
				bitsPerSample:8
				samplesPerPixel:3
				hasAlpha:NO
				isPlanar:NO
				colorSpaceName:NSDeviceRGBColorSpace
				bytesPerRow:bytesperline(gscreen->r, 32)
				bitsPerPixel:gscreen->depth];
	gscreen->data->allocd = 0;	/* export into bits */

DBG	NSLog(@"attachscreen %d %d %d×%d",
		gscreen->r.min.x, gscreen->r.min.y, Dx(gscreen->r), Dy(gscreen->r));

	*screenr = gscreen->r;
	*chan = gscreen->chan;
	*depth = gscreen->depth;
	*width = gscreen->width;
	*softscreen = 1;

//	[view setHidden:NO];
//	[win performSelectorOnMainThread:@selector(makeKeyAndOrderFront:) withObject:nil waitUntilDone:NO];
	[win makeKeyAndOrderFront:nil];
	[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
	[NSApp activateIgnoringOtherApps:YES];

	return gscreen->data->bdata;
}

void
flushmemscreen(Rectangle r)
{
//	NSRect dr;

//	dr = NSMakeRect(r.min.x, r.min.y, Dx(r), Dy(r));

DBG	NSLog(@"flushmemscreen %d %d %d %d", r.min.x, r.min.y, r.max.x, r.max.y);

	[view setHidden:NO];
	[win flushWindow];
	[win display];
}

char*
clipread(void)
{
	return nil;
}

int
clipwrite(char *snarf)
{
	return 0;
}

void
setpointer(int x, int y)
{
}

void
drawcursor(Drawcursor* c)
{
}

@implementation Appwin
- (BOOL)canBecomeKeyWindow	{ return YES; }
@end

@implementation Contentview

- (void)drawRect:(NSRect)r
{
	CGContextRef gc;
	CGImageRef i;

DBG	NSLog(@"drawRect %.0f %.0f %.0f %.0f", r.origin.x, r.origin.y, r.size.width, r.size.height);

	if([self lockFocusIfCanDraw] == NO){
DBG		NSLog(@"can't draw", r.size.width, r.size.height);
		return;
	}

	i = CGImageCreateWithImageInRect([bits CGImage], NSRectToCGRect(r));
	gc = [[win graphicsContext] graphicsPort];

	CGContextSaveGState(gc);
	CGContextDrawImage(gc, NSRectToCGRect(r), i);
	CGContextRestoreGState(gc);
	CGContextFlush(gc);
	CGImageRelease(i);
	[self unlockFocus];
}
@end

