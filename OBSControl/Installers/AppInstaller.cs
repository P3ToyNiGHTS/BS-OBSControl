using OBSControl.HarmonyPatches;
using OBSControl.Managers;
using OBSControl.Utilities;
using OBSWebsocketDotNet;
using Zenject;

namespace OBSControl.Installers;

internal class AppInstaller : Installer
{
    private readonly PluginConfig pluginConfig;

    public AppInstaller(PluginConfig pluginConfig)
    {
        this.pluginConfig = pluginConfig;
    }

    public override void InstallBindings()
    {
        Container.BindInstance(pluginConfig).AsSingle();

        //var obsWebsocket = new OBSWebsocket();
        //obsWebsocket.Logger = new IpaLoggerAdapter<OBSWebsocket>(Plugin.Log);
        //Container.Bind<IOBSWebsocket>().FromInstance(obsWebsocket);

        Container.Bind<IOBSWebsocket>().FromInstance(new OBSWebsocket());

        // OBS Managers
        Container.BindInterfacesAndSelfTo<ConnectionManager>().AsSingle();
        Container.BindInterfacesAndSelfTo<EventManager>().AsSingle();
        Container.BindInterfacesAndSelfTo<SceneManager>().AsSingle();
        Container.BindInterfacesAndSelfTo<RecordingManager>().AsSingle();
        Container.BindInterfacesAndSelfTo<StreamingManager>().AsSingle();

        // Patches
        Container.BindInterfacesTo<HarmonyPatchManager>().AsSingle();
        Container.BindInterfacesTo<StartLevelButtonHook>().AsSingle();
    }
}