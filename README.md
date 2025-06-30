# Segment-Addition-Demo
A proof-of-concept demonstration of the Segment Addition technique for redirected walking in virtual reality.

Navigation through a virtual environment is one of the most common tasks in Virtual Reality (VR). The most natural navigation method is real walking where the user physically walks through a real space as they navigate in a virtual environment. This improves the user's sense of presence compared to other common locomotion techniques such as walking-in-place or joystick control. Additionally, the body-based cues from walking aid in navigation and search-related tasks. Users generally  prefer natural walking to other navigation methods. With these advantages, many applications could benefit from the use of real walking. 

However, while virtual worlds can be expansive, the physical space the user can walk in is limited. To safely walk while immersed in a virtual environment, custom equipment (such as treadmills) or physical tracking space must be set aside. Many users experience virtual reality in their own homes with consumer grade hardware, where restricted room space limits the tracking space. Redirected walking allows users to walk in a virtual environment that is larger than the physical tracking space.

Segment Addition is a redirected walking technique that uses the concepts of Change Blindness and Environment Manipulationin Virtual Reality. Segment Addition adds or subtracts pieces (called slices) to and from the environment outside the user’s field of view (FOV). The addition of slices allows the system to control the amount a user turns to reach their goal in both the tracking space and the virtual environment. The direction the user is facing after the turn is optimised to keep them within the tracking space. This technique can be used in wide open virtual spaces, even when few obstacles are present. 

This project is a proof-of-concept design for the Segment Addition technique and was originally used as part of a user study to test the efficacy of the technique. It was originally run on a Meta Quest 2 headset, however with Godot's OpenXR tools it should be possible to port the system to work with most other commercial headsets with some adaptation.


# Importation Steps
This project was built using Godot 4.1.1, for best performance open this project using that version of the engine.
The project relies on two add-ons to run which can be imported directly into godot and are NOT part of this git repository:
1. godot XR-Tools
2. xr-simulator

Additionally to run the project on an Oculus Quest 2 headset, android build templates will need to be installed. See this tutorial: https://docs.godotengine.org/en/stable/tutorials/xr/deploying_to_android.html and https://docs.godotengine.org/en/stable/tutorials/xr/index.html#godot-xr-tools for details.
