Contents of ZIP file
====================
- README.txt                            - This file
- fslogix.adml/admx                     - FSLogix group policy definitions

Win32\Release (subfolder) - for 32 bit systems
- FSLogixAppsSetup.exe                  - FSLogix Apps Agent installer 
- FSLogixAppsRuleEditorSetup.exe        - FSLogix Apps Rule Editor installer
- FSLogixAppsJavaRuleEditorSetup.exe    - FSLogix Apps Java Rule Editor installer
               
x64\Release (subfolder) - for 64 bit systems
- FSLogixAppsSetup.exe                  - FSLogix Apps Agent installer
- FSLogixAppsRuleEditorSetup.exe        - FSLogix Apps Rule Editor installer
- FSLogixAppsJavaRuleEditorSetup.exe    - FSLogix Apps Java Rule Editor installer


Applications Included On Install
================================
Default location: 'C:\Program Files\FSLogix\Apps'

- FrxTray.exe                           - FSLogix Profile system tray status utility                                 
- ConfigurationTool.exe                 - FSLogix Profile Configuration Tool
- FrxContext.exe                        - FSLogix vhd(x) context manager 


FSLogix Apps Windows Versions Supported
=======================================
Windows 7 (and later), Windows Server 2008 R2 (and later), 32 and 64 bit
Note: Multi-user Search Database Roaming is supported on Windows 8 (and later), Windows Server 2012 (and later), 32 and 64 bit


Office 365 Container ADMX Template
==================================
To use the ADMX template, copy "fslogix.admx" to C:\Windows\PolicyDefinitions, and "fslogix.adml" to C:\Windows\PolicyDefinitions\en-US.  Remove any previous versions of these files.


Online Documentation
====================
The latest version of the documentation is located on our website at: http://docs.fslogix.com
  Installation instructions: Section "FSLogix Apps Agent Installation"
  Unattended installation instructions: Section "FSLogix Apps Agent Installation | Agent Unattended Installation"
  Quick Start Guides: Section "Quick Start Guides"


Best Practices
==============
The best practices document is located on our website at: http://www.fslogix.com/best-practices


Support Forum and Known Issues
==============================
The support forum is located on our website at: https://support.fslogix.com
The list of Known Issues with the product is maintained there
New versions of this product are announced in the Announcements section of the Forum


Sample Rule Files
=================
Sample Rule Files are available for download from our website at: http://www.fslogix.com/downloads


Acknowledgements (Please see the links for copyright and license restrictions)
================
This software makes use of the pugixml library (http://pugixml.org).
pugixml is Copyright (C) 2006-2014 Arseny Kapoulkine.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

This software makes use of the SimpleOpt library (http://code.jellycan.com/simpleopt-doc/SimpleOpt_8h.html)
Copyright (c) 2006-2013, Brodie Thiesfield
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

This software makes use of QT (http://qt-project.org/doc/qt-5/lgpl.html)
The Qt Toolkit is Copyright (C) 2013 Digia Plc and/or its subsidiary(-ies) and other contributors.

This software makes use of the WiX Toolset (http://wixtoolset.org/documentation/manual/v3/main/license.html)

This software makes use of the C++ REST SDK (https://casablanca.codeplex.com/license)