#!/usr/bin/python

"""
 Simulation of a rotating 3D Cube
 Developed by Leonel Machava <leonelmachava@gmail.com>

 http://codeNtronix.com
 
 License:
 Unless otherwise noted, all code available on this site is under the MIT license. You can access the license at http://opensource.org/licenses/mit-license.php
 
 Extended by Seraphim Sense Ltd.:
 * Create separate graphics thread
 * Plot acceleration magnitude
 * Add simulation mode when cube.py is invoked directly
 
"""

import sys, math, pygame
from operator import itemgetter
import threading
import random
from collections import deque

ACCEL_ONE_G = 16384

class Point3D:
    def __init__(self, x = 0, y = 0, z = 0):
        self.x, self.y, self.z = float(x), float(y), float(z)
 
    def rotateX(self, angle):
        """ Rotates the point around the X axis by the given angle in degrees. """
        rad = angle * math.pi / 180
        cosa = math.cos(rad)
        sina = math.sin(rad)
        y = self.y * cosa - self.z * sina
        z = self.y * sina + self.z * cosa
        return Point3D(self.x, y, z)
 
    def rotateY(self, angle):
        """ Rotates the point around the Y axis by the given angle in degrees. """
        rad = angle * math.pi / 180
        cosa = math.cos(rad)
        sina = math.sin(rad)
        z = self.z * cosa - self.x * sina
        x = self.z * sina + self.x * cosa
        return Point3D(x, self.y, z)
 
    def rotateZ(self, angle):
        """ Rotates the point around the Z axis by the given angle in degrees. """
        rad = angle * math.pi / 180
        cosa = math.cos(rad)
        sina = math.sin(rad)
        x = self.x * cosa - self.y * sina
        y = self.x * sina + self.y * cosa
        return Point3D(x, y, self.z)
 
    def project(self, win_width, win_height, fov, viewer_distance):
        """ Transforms this 3D point to 2D using a perspective projection. """
        factor = fov / (viewer_distance + self.z)
        x = self.x * factor + win_width / 2
        y = -self.y * factor + win_height / 2
        return Point3D(x, y, self.z)

class Graphics(threading.Thread):
    def __init__(self, win_width = 640, win_height = 480):
        threading.Thread.__init__(self)
        self.cube_pane_height = win_height * 0.8
        self.accelPoints = []
        self.accelW = 200
        self.angleX = 0
        self.angleY = 0
        self.angleZ = 0
        pygame.init()

        self.screen = pygame.display.set_mode((win_width, win_height))
        pygame.display.set_caption("Gyro 3D With Angel Sensor")
        
        self.clock = pygame.time.Clock()

        self.vertices = [
            Point3D(-1,1,-1),
            Point3D(1,1,-1),
            Point3D(1,-1,-1),
            Point3D(-1,-1,-1),
            Point3D(-1,1,1),
            Point3D(1,1,1),
            Point3D(1,-1,1),
            Point3D(-1,-1,1)
        ]

        # Define the vertices that compose each of the 6 faces. These numbers are
        # indices to the vertices list defined above.
        self.faces  = [(0,1,2,3),(1,5,6,2),(5,4,7,6),(4,0,3,7),(0,4,5,1),(3,2,6,7)]

        # Define colors for each face
        self.colors = [(255,0,255),(255,0,0),(0,255,0),(0,0,255),(0,255,255),(255,255,0)]

        self.angle = 0
        self.isTerminated = False
    
    def terminate(self):
        self.isTerminated = True
    
    def rotateX(self, angle):
        self.angleX += angle

    def rotateY(self, angle):
        self.angleY += angle
        
    def rotateZ(self, angle):
        self.angleZ += angle
        
    def run(self):
        """ Main Loop """
        while not self.isTerminated:
            self.clock.tick(100) # Support 100Hz at most
            self.screen.fill((0,32,0))

            # It will hold transformed vertices.
            t = []
            
            for v in self.vertices:
                # Rotate the point around X axis, then around Y axis, and finally around Z axis.
                r = v.rotateX(self.angleX).rotateY(self.angleY).rotateZ(self.angleZ)
                
                # Transform the point from 3D to 2D
                p = r.project(self.screen.get_width(), self.cube_pane_height, 256, 4)
                
                # Put the point in the list of transformed vertices
                t.append(p)

            # Calculate the average Z values of each face.
            avg_z = []
            i = 0
            for f in self.faces:
                z = (t[f[0]].z + t[f[1]].z + t[f[2]].z + t[f[3]].z) / 4.0
                avg_z.append([i,z])
                i = i + 1

            # Draw the faces using the Painter's algorithm:
            # Distant faces are drawn before the closer ones.
            for tmp in sorted(avg_z,key=itemgetter(1),reverse=True):
                face_index = tmp[0]
                f = self.faces[face_index]
                pointlist = [(t[f[0]].x, t[f[0]].y), (t[f[1]].x, t[f[1]].y),
                             (t[f[1]].x, t[f[1]].y), (t[f[2]].x, t[f[2]].y),
                             (t[f[2]].x, t[f[2]].y), (t[f[3]].x, t[f[3]].y),
                             (t[f[3]].x, t[f[3]].y), (t[f[0]].x, t[f[0]].y)]
                pygame.draw.polygon(self.screen,self.colors[face_index],pointlist)

            self.drawAccel()
            pygame.display.flip()
        return

    def drawAccel(self):
        signal = self.accelPoints
        if len(signal) < 2: return
        prescaler = max(signal) - min(signal) or 1
        x = 0
        h = 100
        dc = sum(signal) / len(signal)
        points = deque([])
        for y in signal:
            scaledY = self.screen.get_height() - h/2 - ((y-dc) * h / prescaler)
            points.append((x, scaledY))
            x = x + self.screen.get_width()/self.accelW
        pygame.draw.lines(self.screen, (255,0,255), False, points, 2)
        
    def addAccel(self, accel):
        self.accelPoints.append(accel)
        if len(self.accelPoints) > self.accelW:
            del self.accelPoints[0]
        
if __name__ == "__main__":
    sim = Graphics()
    sim.start()
    for i in range(640):
        sim.addAccel(ACCEL_ONE_G + random.randint(-1000,1000))
    
    print 'Press ESC or Ctrl-C to exit'
    stop = False
    while not stop:
        for event in pygame.event.get():
            if event.type == pygame.QUIT or \
               (event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE):
                sim.terminate()
                stop = True
                break
        sim.rotateX(1)
        sim.rotateY(1)
        sim.rotateZ(1)
        sim.addAccel(ACCEL_ONE_G + random.randint(-1000,1000))
        pygame.time.wait(10)
    pygame.quit()
