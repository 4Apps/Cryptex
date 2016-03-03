# Cryptex Help
=========

Cryptex is a text editor that will encrypt any textual information using two strong encryption algorithms - 128bit [AES][1] and 128bit [Twofish][2]. Even more, it will first encrypt your text using AES and then the encrypt encrypted data once more using Twofish. Cryptex also hashes your password into a salted key thats is being used for encryption and does it a lot of times with two different algorithms ([Whirlpool-512][3] and [SHA-256][4]) so its a lot harder to use [Brute-force attack][5] to guess your password.


#Features

* AES + Twofish encryption
* Markdown editor
* Sheet management
* Easy to add new notes, passwords, even private keys
* Drag and drop files to insert file's content directly in editor
* Document auto-locking


#Shortcuts:

* Cmd + T - Add a sheet
* Cmd + D - delete current sheet
* Cmd + L - Save and Lock the document
* Cmd + N - New document
* Cmd + W - Close document
* Cmd + Shift + ] - Next sheet
* Cmd + Shift + [ - Previous sheet
* And usual ones, like Cmd + S to save, Cmd + O to open, and more.


[1]: http://en.wikipedia.org/wiki/Advanced_Encryption_Standard "Advanced Encryption Standard"
[2]: http://en.wikipedia.org/wiki/Twofish "Twofish"
[3]: http://en.wikipedia.org/wiki/Whirlpool_(cryptography) "Whirlpool"
[4]: http://en.wikipedia.org/wiki/SHA-2 "SHA-2"
[5]: http://en.wikipedia.org/wiki/Brute-force_attack "Brute-force attack"
