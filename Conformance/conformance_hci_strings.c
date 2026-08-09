/*
 * Differential conformance driver for the HCI string converter family
 * (21 symbols: hci_*tostr/hci_strto*, lmp_*, pal_*).
 *
 * All 21 are exported by the system libbluetooth.so.3 (verified
 * against nm -D), so this driver links against it directly — no
 * BlueZ source tree needed.
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include <bluetooth/bluetooth.h>
#include <bluetooth/hci.h>
#include <bluetooth/hci_lib.h>

static void dump_bus(void)
{
	int buses[] = {
		HCI_VIRTUAL, HCI_USB, HCI_PCCARD, HCI_UART, HCI_RS232, HCI_PCI,
		HCI_SDIO, HCI_SPI, HCI_I2C, HCI_SMD, HCI_VIRTIO, HCI_IPC, 99
	};
	size_t i;

	for (i = 0; i < sizeof(buses) / sizeof(*buses); i++) {
		printf("bustostr(%d) = \"%s\"\n", buses[i], hci_bustostr(buses[i]));
		printf("dtypetostr(%d) = \"%s\"\n", buses[i], hci_dtypetostr(buses[i]));
	}

	printf("typetostr(%d) = \"%s\"\n", HCI_PRIMARY, hci_typetostr(HCI_PRIMARY));
	printf("typetostr(%d) = \"%s\"\n", HCI_AMP, hci_typetostr(HCI_AMP));
	printf("typetostr(99) = \"%s\"\n", hci_typetostr(99));
}

static void dump_dflags(void)
{
	uint32_t flags[] = {
		0,
		1 << HCI_UP,
		1 << HCI_INIT,
		(1 << HCI_UP) | (1 << HCI_RUNNING) | (1 << HCI_PSCAN),
		0xFFFFFFFF
	};
	size_t i;

	for (i = 0; i < sizeof(flags) / sizeof(*flags); i++) {
		char *s = hci_dflagstostr(flags[i]);
		printf("dflagstostr(0x%08x) = \"%s\"\n", flags[i], s ? s : "(null)");
		free(s);
	}
}

static void dump_ptype(void)
{
	unsigned int values[] = {
		0, HCI_DM1, HCI_DM1 | HCI_DH1, HCI_DM1 | HCI_DM3 | HCI_DM5 |
			HCI_DH1 | HCI_DH3 | HCI_DH5, 0xFFFF
	};
	size_t i;
	static const char *strs[] = {
		"DM1", "DM1,DH1", "DM1,DH1,BOGUS", "bogus", NULL
	};

	for (i = 0; i < sizeof(values) / sizeof(*values); i++) {
		char *s = hci_ptypetostr(values[i]);
		printf("ptypetostr(0x%04x) = \"%s\"\n", values[i], s ? s : "(null)");
		free(s);

		s = hci_scoptypetostr(values[i]);
		printf("scoptypetostr(0x%04x) = \"%s\"\n", values[i], s ? s : "(null)");
		free(s);
	}

	for (i = 0; strs[i]; i++) {
		unsigned int val = 0xdeadbeef;
		int rc = hci_strtoptype((char *) strs[i], &val);
		printf("strtoptype(\"%s\") = %d val=0x%x\n", strs[i], rc, val);

		val = 0xdeadbeef;
		rc = hci_strtoscoptype((char *) strs[i], &val);
		printf("strtoscoptype(\"%s\") = %d val=0x%x\n", strs[i], rc, val);
	}
}

static void dump_lp_lm(void)
{
	unsigned int values[] = { 0, HCI_LP_RSWITCH, HCI_LP_SNIFF | HCI_LP_PARK, 0xFF };
	size_t i;
	static const char *lp_strs[] = { "RSWITCH", "SNIFF,PARK", "bogus", NULL };
	static const char *lm_strs[] = { "ACCEPT", "MASTER", "CENTRAL,AUTH", "bogus", NULL };

	for (i = 0; i < sizeof(values) / sizeof(*values); i++) {
		char *s = hci_lptostr(values[i]);
		printf("lptostr(0x%02x) = \"%s\"\n", values[i], s ? s : "(null)");
		free(s);

		s = hci_lmtostr(values[i]);
		printf("lmtostr(0x%02x) = \"%s\"\n", values[i], s ? s : "(null)");
		free(s);
	}

	for (i = 0; lp_strs[i]; i++) {
		unsigned int val = 0xdeadbeef;
		int rc = hci_strtolp((char *) lp_strs[i], &val);
		printf("strtolp(\"%s\") = %d val=0x%x\n", lp_strs[i], rc, val);
	}

	for (i = 0; lm_strs[i]; i++) {
		unsigned int val = 0xdeadbeef;
		int rc = hci_strtolm((char *) lm_strs[i], &val);
		printf("strtolm(\"%s\") = %d val=0x%x\n", lm_strs[i], rc, val);
	}
}

static void dump_commands(void)
{
	unsigned int cmds[] = { 0, 1, 227, 231, 9999 };
	size_t i;
	uint8_t bitmap[64];

	for (i = 0; i < sizeof(cmds) / sizeof(*cmds); i++) {
		char *s = hci_cmdtostr(cmds[i]);
		printf("cmdtostr(%u) = \"%s\"\n", cmds[i], s ? s : "(null)");
		free(s);
	}

	memset(bitmap, 0, sizeof(bitmap));
	bitmap[0] = 0x01; /* bit 0: Inquiry */
	bitmap[0] |= 0x02; /* bit 1: Inquiry Cancel */
	bitmap[28] |= 0x08; /* bit 227: LE Read Supported States */
	{
		char *s = hci_commandstostr(bitmap, "  ", 60);
		printf("commandstostr(narrow) = \"%s\"\n", s ? s : "(null)");
		free(s);

		s = hci_commandstostr(bitmap, NULL, 200);
		printf("commandstostr(wide, no pref) = \"%s\"\n", s ? s : "(null)");
		free(s);
	}
}

static void dump_versions(void)
{
	unsigned int values[] = { 0x00, 0x09, 0x0d, 0xff };
	size_t i;
	static const char *strs[] = { "5.0", "1.0b", "bogus", NULL };

	for (i = 0; i < sizeof(values) / sizeof(*values); i++) {
		char *s = hci_vertostr(values[i]);
		printf("vertostr(0x%02x) = \"%s\"\n", values[i], s ? s : "(null)");
		free(s);

		s = lmp_vertostr(values[i]);
		printf("lmp_vertostr(0x%02x) = \"%s\"\n", values[i], s ? s : "(null)");
		free(s);
	}

	{
		unsigned int palValues[] = { 0x00, 0x01, 0xff };
		for (i = 0; i < sizeof(palValues) / sizeof(*palValues); i++) {
			char *s = pal_vertostr(palValues[i]);
			printf("pal_vertostr(0x%02x) = \"%s\"\n", palValues[i], s ? s : "(null)");
			free(s);
		}
	}

	for (i = 0; strs[i]; i++) {
		unsigned int ver = 0xdeadbeef;
		int rc = hci_strtover((char *) strs[i], &ver);
		printf("strtover(\"%s\") = %d ver=0x%x\n", strs[i], rc, ver);

		ver = 0xdeadbeef;
		rc = lmp_strtover((char *) strs[i], &ver);
		printf("lmp_strtover(\"%s\") = %d ver=0x%x\n", strs[i], rc, ver);

		ver = 0xdeadbeef;
		rc = pal_strtover((char *) strs[i], &ver);
		printf("pal_strtover(\"%s\") = %d ver=0x%x\n", strs[i], rc, ver);
	}
}

static void dump_features(void)
{
	uint8_t features[8];
	char *s;

	memset(features, 0, sizeof(features));
	features[0] = LMP_3SLOT | LMP_5SLOT | LMP_ENCRYPT;
	features[4] = LMP_LE;
	features[6] = LMP_SIMPLE_PAIR;

	s = lmp_featurestostr(features, NULL, 200);
	printf("lmp_featurestostr(wide) = \"%s\"\n", s ? s : "(null)");
	free(s);

	s = lmp_featurestostr(features, "\t", 30);
	printf("lmp_featurestostr(narrow) = \"%s\"\n", s ? s : "(null)");
	free(s);

	memset(features, 0xff, sizeof(features));
	s = lmp_featurestostr(features, NULL, 200);
	printf("lmp_featurestostr(all) = \"%s\"\n", s ? s : "(null)");
	free(s);
}

int main(void)
{
	dump_bus();
	dump_dflags();
	dump_ptype();
	dump_lp_lm();
	dump_commands();
	dump_versions();
	dump_features();
	return 0;
}
