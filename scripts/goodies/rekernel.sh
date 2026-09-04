#!/bin/bash

case "$REKERNEL_SELECTOR" in
    rekernel)
        # Execute rekernel setup function
        rekernel_setup
        ;;
    none|"")
        echo "-- ReKernel is not selected."
        ;;
    *)
        echo "- Invalid REKERNEL_SELECTOR: $REKERNEL_SELECTOR. Valid options: rekernel, none."
        exit 1
        ;;
esac