/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package edu.illinois.rokwire.mobile_access;

import android.content.Context;

import com.hid.origo.OrigoKeysApiFactory;
import com.hid.origo.api.OrigoApiConfiguration;
import com.hid.origo.api.OrigoMobileKeys;
import com.hid.origo.api.OrigoMobileKeysApi;
import com.hid.origo.api.OrigoReaderConnectionController;
import com.hid.origo.api.ble.OrigoBluetoothMode;
import com.hid.origo.api.ble.OrigoOpeningTrigger;
import com.hid.origo.api.ble.OrigoScanConfiguration;
import com.hid.origo.api.ble.OrigoSeamlessOpeningTrigger;
import com.hid.origo.api.ble.OrigoTapOpeningTrigger;
import com.hid.origo.api.ble.OrigoTwistAndGoOpeningTrigger;
import com.hid.origo.api.hce.OrigoNfcConfiguration;

import edu.illinois.rokwire.BuildConfig;
import edu.illinois.rokwire.Constants;
import edu.illinois.rokwire.rokwire_plugin.Utils;

public class MobileAccessKeysApiFactory implements OrigoKeysApiFactory {

    private OrigoMobileKeysApi mobileKeysApi;

    public MobileAccessKeysApiFactory(Context appContext) {
        initFactory(appContext);
    }

    private void initFactory(Context appContext) {
        if (mobileKeysApi == null) {
            mobileKeysApi = OrigoMobileKeysApi.getInstance();
        }
        if (!mobileKeysApi.isInitialized()) {
            String appId = BuildConfig.ORIGO_APP_ID;
            String appDescription = String.format("%s-%s", BuildConfig.ORIGO_APP_ID, BuildConfig.VERSION_NAME);
            Integer[] lockServiceCodes = getStoredLockServiceCodes(appContext);

            OrigoOpeningTrigger[] openingTriggers = isTwistAndGoEnabled(appContext) ?
                    new OrigoOpeningTrigger[]{new OrigoTwistAndGoOpeningTrigger(appContext), new OrigoTapOpeningTrigger(appContext), new OrigoSeamlessOpeningTrigger()} :
                    new OrigoOpeningTrigger[]{new OrigoTapOpeningTrigger(appContext), new OrigoSeamlessOpeningTrigger()};

            OrigoScanConfiguration origoScanConfiguration = new OrigoScanConfiguration.Builder(
                    openingTriggers, lockServiceCodes)
                    .setAllowBackgroundScanning(true)
                    .setBluetoothModeIfSupported(OrigoBluetoothMode.DUAL)
                    .build();

            OrigoApiConfiguration origoApiConfiguration = new OrigoApiConfiguration.Builder().setApplicationId(appId)
                    .setApplicationDescription(appDescription)
                    .setNfcParameters(new OrigoNfcConfiguration.Builder().build())
                    .build();

            mobileKeysApi.initialize(appContext, origoApiConfiguration, origoScanConfiguration, appId);
            if (!mobileKeysApi.isInitialized()) {
                throw new IllegalStateException();
            }
        }
    }

    //region OrigoKeysApiFactory implementation

    @Override
    public OrigoMobileKeys getMobileKeys() {
        return mobileKeysApi.getMobileKeys();
    }

    @Override
    public OrigoReaderConnectionController getReaderConnectionController() {
        return mobileKeysApi.getOrigiReaderConnectionController();
    }

    @Override
    public OrigoScanConfiguration getOrigoScanConfiguration() {
        return getReaderConnectionController().getScanConfiguration();
    }

    //endregion

    //region Shared prefs helpers

    private boolean isTwistAndGoEnabled(Context appContext) {
        return Utils.AppSharedPrefs.getBool(appContext, Constants.MOBILE_ACCESS_TWIST_AND_GO_ENABLED_PREFS_KEY, false);
    }

    private Integer[] getStoredLockServiceCodes(Context appContext) {
        String storedLockServiceCodesValue = Utils.AppSecureSharedPrefs.getString(appContext, Constants.MOBILE_ACCESS_LOCK_SERVICE_CODES_PREFS_KEY, null);
        if (!Utils.Str.isEmpty(storedLockServiceCodesValue)) {
            String[] lockCodesStringArr = storedLockServiceCodesValue.split(Constants.MOBILE_ACCESS_LOCK_SERVICE_CODES_DELIMITER);
            Integer[] lockCodes = new Integer[lockCodesStringArr.length];
            for (int i = 0; i < lockCodesStringArr.length; i++) {
                lockCodes[i] = Integer.parseInt(lockCodesStringArr[i]);
            }
            return lockCodes;
        }
        return new Integer[]{BuildConfig.ORIGO_LOCK_SERVICE_CODE}; // Default Lock Service Code
    }

    //endregion
}
