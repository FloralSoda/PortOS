# PortOS
PortOS is an operating framework designed for Dan200's [ComputerCraft](https://www.curseforge.com/minecraft/mc-mods/computercraft), SquidDev's [CC:Tweaked](https://modrinth.com/mod/cc-tweaked) and MerithTK's [CC:Restitched](https://modrinth.com/mod/cc-restitched). It is written in [Lua](https://www.lua.org/), designed to support all major versions of ComputerCraft using the version patching system, provided the [HTTP API](https://tweaked.cc/module/http.html) is enabled. I plan to make pre-made zips for popular versions, so an admin can drag and drop the contents into a PC to make copies if they do not want to enable the HTTP API.

In its current state, PortOS would be better described as an Application Framework, though over time PortOS will bring technologies that would hopefully earn it the title of an Operating Framework and UI (The closest thing an program can get to an OS on ComputerCraft).

PortOS is developed using CraftOS-PC, but is also tested in running versions of ComputerCraft. It is inspired by Microsoft's .NET Framework, Google's Android and various Linux distributions.

PortOS aims to provide developers with a version agnostic, stable and featureful toolkit with which to develop their applications, including but not limited to:
* Application and Controls
* Task scheduling and Retention
* Crash Handling
* Cross-Restart processing (Continue running even after PC/Turtle restart)
* Subscription-based event system
* Hyperthreading (Multithreading but running on one core)
* Cryptographic tools
* Registry
* Networking

If you wish to enjoy these features, but need/want the portability into Computercraft systems that aren't running PortOS, there is an upcoming conversion tool that automatically converts everything into a single lua file with minimal wasted functionality. 
There will also be, alternatively, a server version that lets you host PortOS on one machine, such that you only need to load a small lightweight app to download the required PortOS functions called.

We also aim to provide a clean and user-friendly experience outside of development, with an innovative interaction system inspired by games consoles and phones, as well as a clean and powerful file explorer, app store and other such features.

PortOS also adds some new features to Lua to make the use of objects easier, primarily the class system.

## Wiki
The wiki will be uploaded once PortOS is released. There is an Obsidian vault available, but I haven't uploaded it yet. Until there is a release and wiki, assume the documentation is out of date and take what it says with a grain of salt.
