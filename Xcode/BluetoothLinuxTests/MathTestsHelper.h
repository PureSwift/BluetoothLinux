//
//  MathTestsHelper.h
//  BluetoothLinux
//
//  Created by Alsey Coleman Miller on 3/3/16.
//  Copyright © 2016 PureSwift. All rights reserved.
//

#import <stdint.h>

static inline void hci_set_bit(int nr, void *addr)
{
    *((uint32_t *) addr + (nr >> 5)) |= (1 << (nr & 31));
}

static inline void hci_clear_bit(int nr, void *addr)
{
    *((uint32_t *) addr + (nr >> 5)) &= ~(1 << (nr & 31));
}

static inline int hci_test_bit(int nr, void *addr)
{
    return *((uint32_t *) addr + (nr >> 5)) & (1 << (nr & 31));
}

/* HCI filter tools */
/*
static inline void hci_filter_clear(struct hci_filter *f)
{
    memset(f, 0, sizeof(*f));
}
static inline void hci_filter_set_ptype(int t, struct hci_filter *f)
{
    hci_set_bit((t == HCI_VENDOR_PKT) ? 0 : (t & HCI_FLT_TYPE_BITS), &f->type_mask);
}
static inline void hci_filter_clear_ptype(int t, struct hci_filter *f)
{
    hci_clear_bit((t == HCI_VENDOR_PKT) ? 0 : (t & HCI_FLT_TYPE_BITS), &f->type_mask);
}
static inline int hci_filter_test_ptype(int t, struct hci_filter *f)
{
    return hci_test_bit((t == HCI_VENDOR_PKT) ? 0 : (t & HCI_FLT_TYPE_BITS), &f->type_mask);
}
static inline void hci_filter_all_ptypes(struct hci_filter *f)
{
    memset((void *) &f->type_mask, 0xff, sizeof(f->type_mask));
}
static inline void hci_filter_set_event(int e, struct hci_filter *f)
{
    hci_set_bit((e & HCI_FLT_EVENT_BITS), &f->event_mask);
}
static inline void hci_filter_clear_event(int e, struct hci_filter *f)
{
    hci_clear_bit((e & HCI_FLT_EVENT_BITS), &f->event_mask);
}
static inline int hci_filter_test_event(int e, struct hci_filter *f)
{
    return hci_test_bit((e & HCI_FLT_EVENT_BITS), &f->event_mask);
}
static inline void hci_filter_all_events(struct hci_filter *f)
{
    memset((void *) f->event_mask, 0xff, sizeof(f->event_mask));
}
static inline void hci_filter_set_opcode(int opcode, struct hci_filter *f)
{
    f->opcode = opcode;
}
static inline void hci_filter_clear_opcode(struct hci_filter *f)
{
    f->opcode = 0;
}
static inline int hci_filter_test_opcode(int opcode, struct hci_filter *f)
{
    return (f->opcode == opcode);
}

*/