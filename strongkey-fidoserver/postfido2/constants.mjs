
/**
 * Copyright StrongAuth, Inc. All Rights Reserved.
 *
 * Use of this source code is governed by the GNU Lesser General Public License v2.1
 * The license can be found at https://github.com/StrongKey/fido2/blob/master/LICENSE
 */
// KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
// Here is where various constants used in interacting the FIDO2SERVER are defined.
// Included are the credentials to access FIDO2SERVER, the SKFS request paths and
// APPSERVER metadata info.
const DID = 1;
const PROTOCOL = "FIDO2_0";
const AUTHTYPE = "PASSWORD";
const SVCUSERNAME = "test";
const SVCPASSWORD = "1234";

export const SKFS_HOSTNAME = "fido2tutorial.strongkey.com";
export const SKFS_PORT = "3001";
export const SVCINFO = {
    did: DID,
    protocol: PROTOCOL,
    authtype: AUTHTYPE,
    svcusername: SVCUSERNAME,
    svcpassword: SVCPASSWORD
};

export const SKFS_PREAUTHENTICATE_PATH = '/skfs/rest/preauthenticate'
export const SKFS_AUTHENTICATE_PATH = '/skfs/rest/authenticate'
export const SKFS_PREREGISTRATION_PATH = '/skfs/rest/preregister'
export const SKFS_REGISTRATION_PATH = '/skfs/rest/register'
export const SKFS_GET_KEYS_INFO_PATH = '/skfs/rest/getkeysinfo'
export const SKFS_DEREGISTER_PATH = '/skfs/rest/deregister'

export const METADATA_VERSION = "1.0"
export const METADATA_LOCATION = "Cupertino, CA"

// KKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK
