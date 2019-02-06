//
//  Copyright © 2017 Borna Noureddin. All rights reserved.
//

#import "Renderer.h"
#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#include <chrono>
#include "GLESRenderer.hpp"

// Uniform index.
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_PASSTHROUGH,
    UNIFORM_SHADEINFRAG,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
    ATTRIB_VERTEX,
    ATTRIB_NORMAL,
    NUM_ATTRIBUTES
};

@interface Renderer () {
    GLKView *theView;
    GLESRenderer glesRenderer;
    GLuint programObject;
    std::chrono::time_point<std::chrono::steady_clock> lastTime;

    GLKMatrix4 mvp;
    GLKMatrix3 normalMatrix;
    float touchXInitial;
    float touchYInitial;
    float xDisplacement;
    float yDisplacement;
    float zDisplacement;
    float rotAngle;
    float yRotAngle;
    float xRotAngle;
    float yRot;
    float xRot;
    char isRotating;

    float *vertices, *normals, *texCoords;
    int *indices, numIndices;
    
    
    bool _isRotating;
    bool _isFingerDragging;
}

@end

@implementation Renderer

- (void)dealloc
{
    glDeleteProgram(programObject);
}

- (void)loadModels
{
    numIndices = glesRenderer.GenCube(1.0f, &vertices, &normals, &texCoords, &indices);
}

- (void)setup:(GLKView *)view
{
    view.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    if (!view.context) {
        NSLog(@"Failed to create ES context");
    }
    
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    theView = view;
    [EAGLContext setCurrentContext:view.context];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
    tapGesture.numberOfTapsRequired = 2;
    [theView addGestureRecognizer:tapGesture];
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    panGesture.maximumNumberOfTouches = 1;
    [theView addGestureRecognizer:panGesture];
    UIPanGestureRecognizer *pan2FingerGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan2FingerGesture:)];
    pan2FingerGesture.minimumNumberOfTouches = 2;
    [theView addGestureRecognizer:pan2FingerGesture];
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [theView addGestureRecognizer:pinchGesture];
    if (![self setupShaders])
        return;
    xDisplacement = 0.0f;
    yDisplacement = 0.0f;
    zDisplacement = -5.0f;
    rotAngle = 0.0f;
    yRotAngle = 0.0f;
    xRotAngle = 0.0f;
    isRotating = 1;

    _isRotating = true;
    _isFingerDragging = false;
    
    glClearColor ( 0.0f, 0.0f, 0.0f, 0.0f );
    glEnable(GL_DEPTH_TEST);
    lastTime = std::chrono::steady_clock::now();
}
-(float)getXDisplacement {
    return xDisplacement;
}
-(float)getYDisplacement {
    return yDisplacement;
}
-(float)getZDisplacement {
    return zDisplacement;
}
-(float)getXRotationAngle {
    return fmodf(xRotAngle, 2 * M_PI)* (180 / M_PI);
}
-(float)getYRotationAngle {
    return fmodf(rotAngle + yRotAngle, 2 * M_PI) * (180 / M_PI);
}
-(void)resetCube {
    xDisplacement = 0.0f;
    yDisplacement = 0.0f;
    zDisplacement = -5.0f;
    rotAngle = 0.0f;
    yRotAngle = 0.0f;
    xRotAngle = 0.0f;
}

- (void)handleTapGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateRecognized) {
        //NSLog(@"Double Tapped");
        _isRotating = !_isRotating;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)sender {
    //NSLog(@"Panned");
    if(sender.numberOfTouches <= 1) {
        if(!_isRotating) {
            CGPoint initialCenter = CGPoint();  // The initial center point of the view.
            CGPoint translatedPoint = [sender translationInView:sender.view.superview];
            if(sender.state == UIGestureRecognizerStateBegan) {
                _isFingerDragging = true;
            }
            if(sender.state == UIGestureRecognizerStateChanged) {
                translatedPoint = [sender translationInView:sender.view.superview];
                yRot = translatedPoint.y  - initialCenter.y;
                xRot = translatedPoint.x  - initialCenter.x;
            }
            if(sender.state == UIGestureRecognizerStateEnded) {
                translatedPoint = [sender translationInView:sender.view.superview];
                _isFingerDragging = false;
                xRot = 0.0f;
                yRot = 0.0f;
            }
        }
    }
}

- (void)handlePan2FingerGesture:(UIPanGestureRecognizer *)sender {
    if(!_isRotating) {
       
        if(sender.numberOfTouches == 2) {
            NSLog(@" 2 Finger Panned");
            CGPoint translatedPoint = [sender translationInView:sender.view.superview];
        
            if(sender.state == UIGestureRecognizerStateBegan) {
                touchXInitial = translatedPoint.x;
                touchYInitial = translatedPoint.y;
            }
            if(sender.state == UIGestureRecognizerStateChanged) {
                translatedPoint = [sender translationInView:sender.view.superview];
                xDisplacement += (translatedPoint.x  - touchXInitial) / 1000;
                yDisplacement += -(translatedPoint.y  - touchYInitial) / 1000;
            }
            if(sender.state == UIGestureRecognizerStateEnded) {
                
            }
        }
    }
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)sender {
    if (!_isRotating)
    {
        NSLog(@"Double Pinched");
        
        if (sender.state == UIGestureRecognizerStateBegan || sender.state == UIGestureRecognizerStateChanged) {
            
            zDisplacement *= 1/sender.scale;
            if (zDisplacement > -3.0) {
                zDisplacement = -3;
            } else if (zDisplacement < -18.0 ){
                zDisplacement = -18.0;
            }
        }
    }
}

- (void)update
{
    auto currentTime = std::chrono::steady_clock::now();
    auto elapsedTime = std::chrono::duration_cast<std::chrono::milliseconds>(currentTime - lastTime).count();
    lastTime = currentTime;
    // Perspective
    mvp = GLKMatrix4Translate(GLKMatrix4Identity, xDisplacement, yDisplacement, zDisplacement);
    //NSLog(@"%f %f", xRot, yRot);
    if (_isRotating)
    {
        rotAngle += 0.001f * elapsedTime;
        if (rotAngle >= 2 * M_PI)
            rotAngle = 0.0f;
    } else {
        if (_isFingerDragging) {
            yRotAngle += 0.001f * elapsedTime * yRot / 100;
            if (yRotAngle >= 2 * M_PI) {
                yRotAngle = 0.0f;
            } else if (yRotAngle <= 0.0f)
                yRotAngle = 2 * M_PI;
            xRotAngle += 0.001f * elapsedTime * xRot / 100;
            if (xRotAngle >= 2 * M_PI)
                xRotAngle = 0.0f;
            else if (xRotAngle <= 0.0f)
                xRotAngle = 2 * M_PI;
            
        }
    }
    NSLog(@"xRotAngle %2.1f yRotAngle %2.1f isRotating %d", xRotAngle, yRotAngle, _isRotating && _isFingerDragging);
    NSLog(@"xRot %2.1f yRot %2.1f isRotating %d", xRot, yRot, _isRotating && _isFingerDragging);
   
    mvp = GLKMatrix4Rotate(mvp, yRotAngle, 1, 0, 0 );
   
    mvp = GLKMatrix4Rotate(mvp, xRotAngle, 0, 1, 0 );
    mvp = GLKMatrix4Rotate(mvp, rotAngle, 0.0, 1.0, 0.0 );
    normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(mvp), NULL);

    float aspect = (float)theView.drawableWidth / (float)theView.drawableHeight;
    GLKMatrix4 perspective = GLKMatrix4MakePerspective(60.0f * M_PI / 180.0f, aspect, 1.0f, 20.0f);

    mvp = GLKMatrix4Multiply(perspective, mvp);
}

- (void)draw:(CGRect)drawRect;
{
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)mvp.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, normalMatrix.m);
    glUniform1i(uniforms[UNIFORM_PASSTHROUGH], false);
    glUniform1i(uniforms[UNIFORM_SHADEINFRAG], true);

    glViewport(0, 0, (int)theView.drawableWidth, (int)theView.drawableHeight);
    glClear ( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glUseProgram ( programObject );

    glVertexAttribPointer ( 0, 3, GL_FLOAT,
                           GL_FALSE, 3 * sizeof ( GLfloat ), vertices );
    glEnableVertexAttribArray ( 0 );
    glVertexAttrib4f ( 1, 1.0f, 0.0f, 0.0f, 1.0f );
    glVertexAttribPointer ( 2, 3, GL_FLOAT,
                           GL_FALSE, 3 * sizeof ( GLfloat ), normals );
    glEnableVertexAttribArray ( 2 );
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, FALSE, (const float *)mvp.m);
    glDrawElements ( GL_TRIANGLES, numIndices, GL_UNSIGNED_INT, indices );
}


- (bool)setupShaders
{
    // Load shaders
    char *vShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.vsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.vsh"] pathExtension]] cStringUsingEncoding:1]);
    char *fShaderStr = glesRenderer.LoadShaderFile([[[NSBundle mainBundle] pathForResource:[[NSString stringWithUTF8String:"Shader.fsh"] stringByDeletingPathExtension] ofType:[[NSString stringWithUTF8String:"Shader.fsh"] pathExtension]] cStringUsingEncoding:1]);
    programObject = glesRenderer.LoadProgram(vShaderStr, fShaderStr);
    if (programObject == 0)
        return false;
    
    // Set up uniform variables
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(programObject, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(programObject, "normalMatrix");
    uniforms[UNIFORM_PASSTHROUGH] = glGetUniformLocation(programObject, "passThrough");
    uniforms[UNIFORM_SHADEINFRAG] = glGetUniformLocation(programObject, "shadeInFrag");

    return true;
}

@end

