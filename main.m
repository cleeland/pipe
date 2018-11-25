//
//  main.m
//  LiveScript
//
//  Created by René Puls on 12.01.05.
//  Copyright René Puls 2005. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <sys/types.h>
#include <sys/ptrace.h>

int main(int argc, char *argv[])
{
#ifdef DEPLOYMENT_BUILD
	// Make cracking Pipe a little harder
	ptrace(PT_DENY_ATTACH, 0, 0, 0);
#endif
    return NSApplicationMain(argc,  (const char **) argv);
}
