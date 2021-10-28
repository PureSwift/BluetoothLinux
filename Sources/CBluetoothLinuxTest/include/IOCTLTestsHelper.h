//
//  IOCTLTestsHelper.h
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#ifdef __linux__

#import <stdint.h>
#import <sys/types.h>
#import <sys/ioctl.h>

/* HCI ioctl defines */
#define HCIDEVUP	_IOW('H', 201, int)
#define HCIDEVDOWN	_IOW('H', 202, int)
#define HCIDEVRESET	_IOW('H', 203, int)
#define HCIDEVRESTAT	_IOW('H', 204, int)

#define HCIGETDEVLIST	_IOR('H', 210, int)
#define HCIGETDEVINFO	_IOR('H', 211, int)
#define HCIGETCONNLIST	_IOR('H', 212, int)
#define HCIGETCONNINFO	_IOR('H', 213, int)
#define HCIGETAUTHINFO	_IOR('H', 215, int)

#define HCISETRAW	_IOW('H', 220, int)
#define HCISETSCAN	_IOW('H', 221, int)
#define HCISETAUTH	_IOW('H', 222, int)
#define HCISETENCRYPT	_IOW('H', 223, int)
#define HCISETPTYPE	_IOW('H', 224, int)
#define HCISETLINKPOL	_IOW('H', 225, int)
#define HCISETLINKMODE	_IOW('H', 226, int)
#define HCISETACLMTU	_IOW('H', 227, int)
#define HCISETSCOMTU	_IOW('H', 228, int)

#define HCIBLOCKADDR	_IOW('H', 230, int)
#define HCIUNBLOCKADDR	_IOW('H', 231, int)

#define HCIINQUIRY	_IOR('H', 240, int)

static int hci_ioctl_list[] = {
    HCIDEVUP,
    HCIDEVDOWN,
    HCIDEVRESET,
    HCIDEVRESTAT,
    HCIGETDEVLIST,
    HCIGETDEVINFO,
    HCIGETCONNLIST,
    HCIGETCONNINFO,
    HCIGETAUTHINFO
};
#else
static int hci_ioctl_list[] = {};
#endif
