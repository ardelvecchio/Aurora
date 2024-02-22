using UnityEngine;
using UnityEngine.Rendering.Universal;

public class AuroraFeature: ScriptableRendererFeature
{
    [System.Serializable]
    public class PassSettings
    {
        // Where/when the render pass should be injected during the rendering process.
        public RenderPassEvent renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        
        // Used for any potential down-sampling we will do in the pass.
        [Range(1,4)] public int downsample = 1;
        
        // A variable that's specific to the use case of our pass.
        [Range(10, 6500)] public float innerSphereRadius = 100;
        
        [Range(6500, 7000)] public float outerSphereRadius = 20;
        
        [Range(0.0f, 1.0f)] public float auroraHeight = 0.0f;
        
        [Range(1, 100)] public float numSteps = 50.0f;
        
        [Range(0.1f, 10)] public float density = 0.1f;

        [Range(-60000, 0)] public float sphereHeight = -100.0f;

        [Range(1.0f, 10.0f)] public float auroraScale = 1.0f;
        
        [Range(0.0f, 0.1f)] public float curlStrength= 0.05f;
        
        [Range(0.5f, 10.0f)] public float curlSpeed= 0.05f;
        
        public Texture2D auroraTexture;

        public Texture2D brushTexture;
        
        public Texture2D auroraGradient;
        
        public Texture2D opacityNoise;
        
        [Range(1.0f, 5.0f)] public float opacitySpeed = 1.0f;
        
        public Texture2D OpacityGrad;

        public Texture2D perlinCurl;

        public Texture2D flickerMask;

        [Range(0.0f, 10.0f)] public float earlyOutThreshold = 0.7f;
        
        [Range(0.0f, 10.0f)] public float flickerIntensity= 1.0f;
        
        [Range(0.0f, 10.0f)] public float flickerSpeed= 1.0f;
        
        [Range(-0.5f, 2.0f)] public float verticalIntensity = 1.0f;
        
        [Range(1f, 30.0f)] public float verticalFrequency = 1.0f;

        

        public Color auroraColor;

        // additional properties ...
    }

    // References to our pass and its settings.
    AuroraPass pass;
    public PassSettings passSettings = new();

    // Gets called every time serialization happens.
    // Gets called when you enable/disable the renderer feature.
    // Gets called when you change a property in the inspector of the renderer feature.
    public override void Create()
    {
        // Pass the settings as a parameter to the constructor of the pass.
        pass = new AuroraPass(passSettings);
    }

    // Injects one or multiple render passes in the renderer.
    // Gets called when setting up the renderer, once per-camera.
    // Gets called every frame, once per-camera.
    // Will not be called if the renderer feature is disabled in the renderer inspector.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        // Here you can queue up multiple passes after each other.
        renderer.EnqueuePass(pass); 
    }
}
