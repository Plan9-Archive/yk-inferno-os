#import <Cocoa/Cocoa.h>
#include <stdlib.h>

@interface Listener : NSObject <NSApplicationDelegate> @end
@interface Threader : NSThread @end

int
main(int argc, char* argv[])
{
	[NSApplication sharedApplication];
	[NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
	[[Threader new] start];
	[NSThread detachNewThreadSelector:@selector(stubthread:) toTarget:[Listener class] withObject:NSApp];
	[NSApp setDelegate:[Listener new]];
	[NSApp run];
	return 0;
}

@implementation Listener
- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	printf("applicationDidFinishLaunching\n");
	fflush(stdout);
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	printf("applicationWillTerminate\n");
	fflush(stdout);
}

+ (void)stubthread:(id)arg
{
	[[NSThread currentThread] setName:@"stubthread"];
	printf("stubthread\n");
	fflush(stdout);
	[NSThread exit];
}
@end

@implementation Threader
- (void)main
{
	[self setName:@"tmpthread"];
	printf("Threader.main: %d\n", (int)[self stackSize]);
	fflush(stdout);
	[NSThread exit];
}
@end
