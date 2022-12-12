using System;
using System.Collections.Generic;
using System.Text;

namespace TrialApp.ServiceClient
{
    class AESEncryption
    {
        #region futureuse
        //private static IBuffer GetMD5Hash(string key)
        //{
        //    // Convert the message string to BINARY DATA.
        //    IBuffer buffUtf8Msg = CryptographicBuffer.ConvertStringToBinary(key, BinaryStringEncoding.Utf8);

        //    // Create a HashAlgorithmProvider object.
        //    HashAlgorithmProvider objAlgProv = HashAlgorithmProvider.OpenAlgorithm(HashAlgorithmNames.Md5);

        //    // Hash the message.
        //    IBuffer buffHash = objAlgProv.HashData(buffUtf8Msg);

        //    // Verify that the hash length equals the length specified for the algorithm.
        //    if (buffHash.Length != objAlgProv.HashLength)
        //    {
        //        throw new Exception("There was an error creating the hash");
        //    }


        //    //var pwbyte = System.Text.Encoding.UTF8.GetBytes(key);
        //    //String strBase64 = Convert.ToBase64String(pwbyte);

        //    //// Decoded the string from Base64 to binary.
        //    //IBuffer buffHash = CryptographicBuffer.ConvertStringToBinary(strBase64, BinaryStringEncoding.Utf8);

        //    return buffHash;
        //}
        ///// <summary>
        ///// Encrypt a string using dual encryption method. Returns an encrypted text.
        ///// </summary>
        ///// <param name="toEncrypt">String to be encrypted</param>
        ///// <param name="key">Unique key for encryption/decryption</param>m>
        ///// <returns>Returns encrypted string.</returns>
        //public static string Encrypt(string toEncrypt, string key)// toEncrypt ="Nepal" , key = "Enz@o123"
        //{
        //    try
        //    {
        //        // Get the MD5 key hash (you can as well use THE BINARY of the key string)
        //        var keyHash = GetMD5Hash(key);

        //        var pwbyte = System.Text.Encoding.UTF8.GetBytes(key);

        //        // Create a buffer that contains the encoded message to be encrypted.
        //        var toDecryptBuffer = CryptographicBuffer.ConvertStringToBinary(toEncrypt, BinaryStringEncoding.Utf8);
        //        // Open a symmetric algorithm provider for the specified algorithm.
        //        var aes = SymmetricKeyAlgorithmProvider.OpenAlgorithm(SymmetricAlgorithmNames.AesEcbPkcs7);

        //        // Create a symmetric key.
        //        var symetricKey = aes.CreateSymmetricKey(keyHash);

        //        // The input key must be securely shared between the sender of the cryptic message
        //        // and the recipient. The initialization vector must also be shared but does not
        //        // need to be shared in a secure manner. If the sender encodes a message string
        //        // to a buffer, the binary encoding method must also be shared with the recipient.
        //        var buffEncrypted = CryptographicEngine.Encrypt(symetricKey, toDecryptBuffer, null);

        //        // Convert the encrypted buffer to a string (for display).
        //        // We are using Base64 to convert bytes to string since you might get unmatched characters
        //        // in the encrypted buffer that we cannot convert to string with UTF8.
        //        var strEncrypted = CryptographicBuffer.EncodeToBase64String(buffEncrypted);

        //        return strEncrypted;
        //    }
        //    catch (Exception ex)
        //    {
        //        // MetroEventSource.Log.Error(ex.Message);
        //        return "";
        //    }
        //}
        #endregion

        public static string EncryptAesTest(string data, string password)
        {
            //SymmetricKeyAlgorithmProvider SAP = SymmetricKeyAlgorithmProvider.OpenAlgorithm(SymmetricAlgorithmNames.AesEcbPkcs7);
            //CryptographicKey AES;
            //HashAlgorithmProvider HAP = HashAlgorithmProvider.OpenAlgorithm(HashAlgorithmNames.Sha512);
            //Windows.Security.Cryptography.Core.CryptographicHash Hash_AES = HAP.CreateHash();

            //string encrypted;

            //try
            //{

            //    var pwbyte = System.Text.Encoding.UTF8.GetBytes(password);
            //    String strBase64 = Convert.ToBase64String(pwbyte);


            //    byte[] hash = new byte[16];
            //    Hash_AES.Append(CryptographicBuffer.CreateFromByteArray(System.Convert.FromBase64String(strBase64)));
            //    byte[] temp;
            //    CryptographicBuffer.CopyToByteArray(Hash_AES.GetValueAndReset(), out temp);
            //    Array.Copy(temp, 0, hash, 0, 16);
            //    //Array.Copy(temp, 0, hash, 15, 16);
            //    AES = SAP.CreateSymmetricKey(CryptographicBuffer.CreateFromByteArray(hash));
            //    IBuffer Buffer = CryptographicBuffer.CreateFromByteArray(Encoding.UTF8.GetBytes(data));
            //    encrypted = CryptographicBuffer.EncodeToBase64String(CryptographicEngine.Encrypt(AES, Buffer, null));
            //    return encrypted;
            //}
            //catch
            //{
            //    return "encryption error";
            //}
            return "";
        }



    }
}
