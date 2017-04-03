#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "string.h"
#include "src/crc.h"

#define MAX_HASH_SLOT   16384
#define NOT_FOUND       -1

char * _hash_tag_to_key(char *key) {
    char *openTag = strstr(key, "{");

    if (openTag == NULL) {
        return key;
    }

    int openTagPosition = openTag - key + 1;

    char *closeTag = strstr(key, "}");

    if (closeTag == NULL) {
        return key;
    }

    int closeTagPosition = closeTag - key;

    if (closeTagPosition < openTagPosition) {
        return key;
    }

    int len = closeTagPosition - openTagPosition;

    if (len == 0) {
        return key;
    }

    char *result = malloc((len + 1) * sizeof(char));

    strncpy(result, key + openTagPosition, len);

    result[len] = '\0';

    return result;
}

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

int
_find_node_index(hash_slots_ref, hash_slot)
        SV *    hash_slots_ref
        int     hash_slot
    CODE:
        if (!SvROK(hash_slots_ref) || SvTYPE(SvRV(hash_slots_ref)) != SVt_PVAV) {
            croak("Not an ARRAY ref in outer hash slot list");
        }

        AV * hash_slots = (AV *) SvRV(hash_slots_ref);
        int first = 0;
        int last = av_len(hash_slots) + 1;

        if (last == 0) XSRETURN_IV(NOT_FOUND);

        int start_hash_slot, finish_hash_slot;

        /* check first node */
        SV * first_node_ref = *av_fetch(hash_slots, 0, 0);
        if (!SvROK(first_node_ref) || SvTYPE(SvRV(first_node_ref)) != SVt_PVAV) {
            croak("Not an ARRAY ref in inner hash slot list");
        }

        AV * first_node = (AV *) SvRV(first_node_ref);
        start_hash_slot = SvIV(*av_fetch(first_node, 0, 0));

        if (start_hash_slot < 0) croak("Start hash slot of first inner hash slot list is less than 0");

        if (hash_slot < start_hash_slot) XSRETURN_IV(NOT_FOUND);

        if (hash_slot == start_hash_slot) XSRETURN_IV(first);

        /* check last node */
        SV * last_node_ref = *av_fetch(hash_slots, last - 1, 0);
        if (!SvROK(last_node_ref) || SvTYPE(SvRV(last_node_ref)) != SVt_PVAV) {
            croak("Not an ARRAY ref in inner hash slot list");
        }

        AV * last_node = (AV *) SvRV(last_node_ref);
        int last_node_len = av_len(last_node) + 1;

        if (last_node_len != 2) croak("Inner hash slot list should contains 2 elements");

        finish_hash_slot = SvIV(*av_fetch(last_node, 1, 0));

        if (finish_hash_slot > MAX_HASH_SLOT) croak("Finish hash slot of last inner hash slot is more than 16384");

        if (hash_slot > finish_hash_slot) XSRETURN_IV(NOT_FOUND);

        if (hash_slot == MAX_HASH_SLOT - 1) XSRETURN_IV(last - 1);

        /* start binary search */
        while (first < last) {
            int mid = first + (last - first)/2;

            SV * node_ref = *av_fetch(hash_slots, mid, 0);
            if (!SvROK(node_ref) || SvTYPE(SvRV(node_ref)) != SVt_PVAV) {
                croak("Not an ARRAY ref in inner hash slot list");
            }

            AV * node = (AV *) SvRV(node_ref);
            int node_len = av_len(node) + 1;

            if (node_len != 2) croak("Inner hash slot list should contains 2 elements");

            start_hash_slot = SvIV(*av_fetch(node, 0, 0));
            finish_hash_slot = SvIV(*av_fetch(node, 1, 0));

            if (start_hash_slot <= hash_slot && hash_slot <= finish_hash_slot) {
                XSRETURN_IV(mid);
            }
            else if (hash_slot < start_hash_slot) {
                last = mid;
            }
            else if (finish_hash_slot < hash_slot) {
                first = mid + 1;
            }
        }

        RETVAL = NOT_FOUND;
    OUTPUT:
        RETVAL

char *
_hash_tag_to_key(key)
        char *  key
    OUTPUT:
        RETVAL
