# Aurora
Ray-Marched Aurora Borealis in Unity URP

This Aurora Borealis was made using Unity's Scriptable Render Pipeline. The auroras are ray marched in a post processing shader that I wrote. The idea is as follows:

First we reconstruct the world space position of each uv coordinate in the screen (in our case we sample the depth texture to return early any pixel which is not on the far clipping plane) and then we get the noramlized vector from the camera to this world space position. This is our view direction. 

From here, we can define two spheres mathematically. The spheres will share the same origin, whith one having a larger radius than the other. The distance in between the spheres will be the area we draw our auroras. We define the origin of the spheres as somewhere below the camera. From here we can calculate the intersection point of the ray with the sphere. The radius of our inner sphere will be larger than the vertical distance from our camera to our sphere origin, i.e, our camera will be within the sphere. 

Once we get this intersection point of our view direction with the inner sphere, we can begin to ray march along this path, that is, along the view direction of the ray. This ray will start at the intersection of the inner sphere, and end at the intersection of the outer sphere. At each point along this ray march, we will get the vector from the ray position to the sphere's origin. We can use this to sample, using uv coordinates, a texture that will represent our aurora. 

From here the work is mostley behind us. We can scrolling noise now to create movement in our auroras, and to break up the auroras into different parts. 
