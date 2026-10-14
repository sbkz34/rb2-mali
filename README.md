# rb2-mali

Version de [RB2-Android](https://github.com/moddedrounds/RB2-Android) (v1.2.3) modifiée pour les GPU
Mali (MediaTek Dimensity), qui n'exposent pas `vertexPipelineStoresAndAtomics`.

- `patches/rb2-android-mali-support.patch` : le correctif (moteur ReXGlue + sonde Vulkan + launcher).
- `.github/workflows/build.yml` : recompile uniquement les bibliothèques du moteur
  (`librexruntimerd.so`, `librexgpu-xenosrd.so`, `librb2probe.so`), les remplace dans l'APK officiel
  et le signe. `libmain.so` n'est pas recompilé ; aucune donnée du jeu n'est utilisée ni stockée ici.

L'APK produit se télécharge dans l'onglet **Actions** → dernière exécution → **Artifacts**.

Installation : désinstaller l'appli officielle (signature différente), installer
`RB2-Android-Mali.apk`, puis resélectionner l'ISO de son propre disque.
