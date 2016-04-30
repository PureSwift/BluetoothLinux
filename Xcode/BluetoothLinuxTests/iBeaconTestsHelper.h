//
//  iBeaconTestsHelper.h
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 4/29/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#define EIR_FLAGS                   0X01
#define EIR_NAME_SHORT              0x08
#define EIR_NAME_COMPLETE           0x09
#define EIR_MANUFACTURE_SPECIFIC    0xFF

/* Byte order conversions */
#if __BYTE_ORDER == __LITTLE_ENDIAN
#define htobs(d)  (d)
#define htobl(d)  (d)
#define htobll(d) (d)
#define btohs(d)  (d)
#define btohl(d)  (d)
#define btohll(d) (d)
#elif __BYTE_ORDER == __BIG_ENDIAN
#define htobs(d)  bswap_16(d)
#define htobl(d)  bswap_32(d)
#define htobll(d) bswap_64(d)
#define btohs(d)  bswap_16(d)
#define btohl(d)  bswap_32(d)
#define btohll(d) bswap_64(d)
#else
#error "Unknown byte order"
#endif

typedef struct {
    uint8_t		length;
    uint8_t		data[31];
} __attribute__ ((packed)) le_set_advertising_data_cp;

static inline unsigned int twoc(int in, int t)
{
    return (in < 0) ? (in + (2 << (t-1))) : in;
}

static inline unsigned int *uuid_str_to_data(char *uuid)
{
    char conv[] = "0123456789ABCDEF";
    int len = strlen(uuid);
    unsigned int *data = (unsigned int*)malloc(sizeof(unsigned int) * len);
    unsigned int *dp = data;
    char *cu = uuid;
    
    for(; cu<uuid+len; dp++,cu+=2)
    {
        *dp = ((strchr(conv, toupper(*cu)) - conv) * 16)
        + (strchr(conv, toupper(*(cu+1))) - conv);
    }
    
    return data;
}

/** Generate iBeacon data from https://github.com/carsonmcdonald/bluez-ibeacon */
static inline le_set_advertising_data_cp beaconAdvertisementData(const unsigned char *uuid, int major_number, int minor_number, int rssi_value)
{
    
    le_set_advertising_data_cp adv_data_cp;
    memset(&adv_data_cp, 0, sizeof(adv_data_cp));
    
    uint8_t segment_length = 1;
    adv_data_cp.data[adv_data_cp.length + segment_length] = htobs(EIR_FLAGS); segment_length++;
    adv_data_cp.data[adv_data_cp.length + segment_length] = htobs(0x1A); segment_length++;
    adv_data_cp.data[adv_data_cp.length] = htobs(segment_length - 1);
    
    adv_data_cp.length += segment_length;
    
    segment_length = 1;
    adv_data_cp.data[adv_data_cp.length + segment_length] = htobs(EIR_MANUFACTURE_SPECIFIC); segment_length++;
    adv_data_cp.data[adv_data_cp.length + segment_length] = htobs(0x4C); segment_length++;
    adv_data_cp.data[adv_data_cp.length + segment_length] = htobs(0x00); segment_length++;
    adv_data_cp.data[adv_data_cp.length + segment_length] = htobs(0x02); segment_length++;
    adv_data_cp.data[adv_data_cp.length + segment_length] = htobs(0x15); segment_length++;
    
    int i;
    for(i = 0; i < 16; i++)
    {
        adv_data_cp.data[adv_data_cp.length + segment_length]  = htobs((unsigned char)uuid[i]); segment_length++;
    }
    
    // Major number
    adv_data_cp.data[adv_data_cp.length + segment_length] = htobs(major_number >> 8 & 0x00FF); segment_length++;
    adv_data_cp.data[adv_data_cp.length + segment_length] = htobs(major_number & 0x00FF); segment_length++;
    
    // Minor number
    adv_data_cp.data[adv_data_cp.length + segment_length] = htobs(minor_number >> 8 & 0x00FF); segment_length++;
    adv_data_cp.data[adv_data_cp.length + segment_length] = htobs(minor_number & 0x00FF); segment_length++;
    
    // RSSI calibration
    adv_data_cp.data[adv_data_cp.length + segment_length] = htobs(twoc(rssi_value, 8)); segment_length++;
    
    adv_data_cp.data[adv_data_cp.length] = htobs(segment_length - 1);
    
    adv_data_cp.length += segment_length;
    
    return adv_data_cp;
}
