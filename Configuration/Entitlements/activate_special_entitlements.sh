#!/bin/bash

ENTITLEMENTS_FILE="${TARGET_TEMP_DIR}/${FULL_PRODUCT_NAME}.xcent"

if [[ $CI && $CONFIGURATION != "Release" ]]; then
  echo "warning: Critical alerts disabled for CI"
elif [[ ${ENABLE_CRITICAL_ALERTS} -eq 1 ]]; then
    /usr/libexec/PlistBuddy -c "add com.apple.developer.usernotifications.critical-alerts bool true" "$ENTITLEMENTS_FILE"
else
    echo "warning: Critical alerts disabled"
fi


if [[ $TARGET_NAME = "App" ]]; then
  if [[ $CI && $CONFIGURATION != "Release" ]]; then
    echo "warning: Device name disabled for CI"
  elif [[ ${ENABLE_DEVICE_NAME} -eq 1 ]]; then
      /usr/libexec/PlistBuddy -c "add com.apple.developer.device-information.user-assigned-device-name bool true" "$ENTITLEMENTS_FILE"
  else
      echo "warning: Device name disabled"
  fi
fi
