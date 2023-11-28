/**
 * Copyright StrongAuth, Inc. All Rights Reserved.
 *
 * Use of this source code is governed by the GNU Lesser General Public License v2.1
 * The license can be found at https://github.com/StrongKey/fido2/blob/master/LICENSE
 */
 // JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ
// Here is where we add encoding and decoding functions used in translating FIDO2
// authenticator challenges and responses. Challenges must be converted from Base64
// to Buffer before being sent to the FIDO2 authenticator and the response given by
// the FIDO2 authenticator must be translated from a Buffer to Base64 before it can
// be sent back to the FIDO2SERVER.

 // JJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJJ
