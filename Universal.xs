#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "src/crc.h"

#define MAX_HASH_SLOT   16384

MODULE = Redis::Cluster::Universal		PACKAGE = Redis::Cluster::Universal

PROTOTYPES: DISABLE

int
_get_hash_slot_by_key(key)
        unsigned const char *    key
    CODE:
        crc keyCRC = crc16(key, strlen(key));
        RETVAL = keyCRC % MAX_HASH_SLOT;
    OUTPUT:
        RETVAL
