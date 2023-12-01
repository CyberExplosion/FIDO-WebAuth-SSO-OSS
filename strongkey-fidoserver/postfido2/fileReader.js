/**
 * Copyright StrongAuth, Inc. All Rights Reserved.
 *
 * Use of this source code is governed by the GNU Lesser General Public License v2.1
 * The license can be found at https://github.com/StrongKey/fido2/blob/master/LICENSE
 */
import { readFile, appendFile } from 'fs';


//write requested files to the client
export function fileReader(filename,contentType,req,res){
    filename = "./templates" + filename;
    readFile(filename, function(err, data) {
    if (err) {
      res.writeHead(404, {'Content-Type': contentType});
      appendFile('log', "[404] "+Date()+" "+req.url+"\n", function (err) {if (err) throw err;});
      return res.end("404 Not Found");
    }
    res.writeHead(200, {'Content-Type': contentType});
    res.write(data);
    appendFile('log', "[200] "+Date()+" "+req.url+"\n", function (err) {if (err) throw err;});
    return res.end();
    });
}
