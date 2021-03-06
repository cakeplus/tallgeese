#import <Cocoa/Cocoa.h>

#include "ssh_gui.h"
#include "ssh_exts.h"
#include "ssh_ml.h"
#include "ssh_app_prefs.h"
#include "ssh_config_view.h"

@implementation Ssh_gui

-(instancetype)initWithFrame:(NSRect)f
{
	if ((self = [super initWithFrame:f])) {
		self.ml_bridge = [[Ssh_ml alloc] init_with:self];
		self.ssh_output_string = @"";
		self.zipcode_output = @"";
		[self setup_menus];
		[self setup_main_interface];
	}
	return self;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier
 willBeInsertedIntoToolbar:(BOOL)flag
{
	// If You want to add a new toolbar item, make it here and add the
	// identifier to the other two methods related to the toolbar
	return nil;
}

- (NSArray*)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	return @[NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier];
}

- (NSArray*)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	return @[NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier];
}

-(void)setup_menus
{
	NSMenu *menu_bar = [NSMenu new];
	NSMenuItem *app_item = [NSMenuItem new];
	NSMenu *app_menu = [NSMenu new];

	NSMenuItem *quit_item =
		[[NSMenuItem alloc]
			// This should double check if there are any ssh_connections still open
			initWithTitle:@"Quit Tallgeese" action:@selector(terminate:) keyEquivalent:@"q"];

	NSMenuItem *about =
		[[NSMenuItem alloc]
			initWithTitle:@"About Tallgeese" action:@selector(show_about) keyEquivalent:@""];

	NSMenuItem *preferences =
		[[NSMenuItem alloc]
			initWithTitle:@"Preferences..." action:@selector(preferences) keyEquivalent:@","];

	NSArray *add_these =
		@[about, [NSMenuItem separatorItem], preferences, [NSMenuItem separatorItem], quit_item];
	// Add them finally
	for (id iter in add_these)
		[app_menu addItem:iter];

	[menu_bar addItem:app_item];
	[app_item setSubmenu:app_menu];
	[NSApp setMainMenu:menu_bar];
}

// Not working, something about changing the Info.plist
// see: http://stackoverflow.com/questions/501079/how-do-i-make-an-os-x-application-react-when-a-file-picture-etc-is-dropped-on
// http://stackoverflow.com/questions/14526936/drag-and-drop-of-file-on-app-icon-doesnt-work-unless-the-app-is-currently-runni?lq=1
// http://stackoverflow.com/questions/5331774/cocoa-obj-c-open-file-when-dragging-it-to-application-icon?rq=1#

// - (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
// {
// 	NSLog(@"Something dragged");
// }

-(void)show_about
{
	// Notice that if you don't do this as a property, aka holding a
	// strong reference to it then it gets collected and disappears
	// immediately
	NSUInteger flags = NSTitledWindowMask | NSClosableWindowMask;
	NSRect screen_frame = [NSScreen mainScreen].frame;
	CGFloat center_x = CGRectGetMidX(screen_frame);
	CGFloat center_y = CGRectGetMidY(screen_frame);
	NSRect about_frame = NSMakeRect(center_x - 75, center_y - 50, 175, 150);
	self.about_window =
		[[NSWindow alloc]
			initWithContentRect:about_frame styleMask:flags backing:NSBackingStoreBuffered defer:NO];

	NSTextField *about_message =
		[[NSTextField alloc] init_as_label:@"About Tallgeese" with:NSMakeRect(0, 0, 0, 0)];

	NSRect about_message_frame = [about_message frame];
	about_message_frame.origin.x = 10;
	about_message_frame.origin.y = 30;
	[about_message setFrame:about_message_frame];

	// NSDictionary *this_dict =
	// 	@{@"about_message":about_message, @"window_view":self.about_window.contentView};
	// + constraintsWithVisualFormat:options:metrics:views:
	// [button1 setTranslatesAutoresizingMaskIntoConstraints:NO];
	// [about_message setTranslatesAutoresizingMaskIntoConstraints:NO];
	// NSArray *cons =
	// 	[NSLayoutConstraint
	// 		constraintsWithVisualFormat:@"V:[window_view]-10-[about_message]"
	// 												options:NSLayoutFormatAlignAllCenterX
	// 												metrics:nil
	// 													views:this_dict];
	// [about_message addConstraints:cons];

	[self.about_window.contentView addSubview:about_message];
	[self.about_window setLevel:NSNormalWindowLevel + 1];
	[self.about_window makeKeyAndOrderFront:NSApp];
}

-(void)preferences
{
	self.prefs_object = [Ssh_app_prefs new];
	[self.prefs_object show];
}

-(void)setup_main_interface
{
	NSTabView *v = [[NSTabView alloc] initWithFrame:self.frame];
	v.drawsBackground = YES;
	self.ssh_output = [[NSTextView alloc] init];
	[self.ssh_output setTextColor:[NSColor greenColor]];
	[self.ssh_output setBackgroundColor:[NSColor blackColor]];

	NSTabViewItem *first_page =
		[[NSTabViewItem alloc]
			init_with:@"Dashboard" tool_tip:@"Main ssh manipulation" identifier:@"first_page"];

	NSScrollView *ssh_output_scroll = [NSScrollView new];

	[ssh_output_scroll setBorderType:NSNoBorder];
	[ssh_output_scroll setHasVerticalScroller:YES];
	[ssh_output_scroll setHasHorizontalScroller:NO];
	[ssh_output_scroll setAutoresizingMask:NSViewWidthSizable |
										 NSViewHeightSizable];
	// [first_page.view addSubview:ssh_output_scroll];
	first_page.view = ssh_output_scroll;
	// [ssh_output setMinSize:NSMakeSize(0.0, contentSize.height)];
	[self.ssh_output setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[self.ssh_output setVerticallyResizable:YES];
	// [self.ssh_output setBackgroundColor:[NSColor redColor]];
	[self.ssh_output setHorizontallyResizable:NO];
	[self.ssh_output setAutoresizingMask:NSViewWidthSizable];
	// [[ssh_output textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
	[[self.ssh_output textContainer] setWidthTracksTextView:YES];
	[self.ssh_output setEditable:NO];
	[ssh_output_scroll setDocumentView:self.ssh_output];

	NSTextField *input_field =
		[[NSTextField alloc] initWithFrame:NSMakeRect(0, 525, 400, 30)];

	[input_field setTarget:self];
	[input_field setAction:@selector(command_send:)];

	[first_page.view addSubview:input_field];
	NSTabViewItem *second_page =
		[[NSTabViewItem alloc]
			init_with:@"Configuration" tool_tip:@"SSH configs to use" identifier:@"second_page"];

	self.ssh_configs = [[Ssh_config_view alloc] init];
	second_page.view = self.ssh_configs;
	for (id g in @[first_page, second_page])
		[v addTabViewItem:g];

	[self addSubview:v];
}

-(void)command_send:(NSTextField*)sender
{
	NSDictionary *user_configs = [self.ssh_configs get_config_options];
	[self.ml_bridge
			send_ssh_command:user_configs[@"username"] host:user_configs[@"dest"] command:sender.stringValue];
	self.ssh_output.string =
		[self.ssh_output.string stringByAppendingString:self.ssh_output_string];
}

-(void)setup_ui
{
	[self setup_menus];
	[self setup_main_interface];
}

-(void)receive_zipcode_result:(NSString*)s
{
	self.zipcode_output = s;
}

-(void)receive_ssh_output_result:(NSString*)s
{
	self.ssh_output_string = s;
}

@end
