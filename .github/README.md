<div align="center">

![felt logo](../logo.png)

</div>

# Overview

**Felt** is a work-in-progress editor for creating and editing trixel-arts - custom asset files in a video game [FEZ](https://store.steampowered.com/app/224760/FEZ/).

Ultimately, Felt will be able to save and load both trile-sets and art objects conveted into `*.fezts.*` and `*.fezao.*` file bundles produced by [FEZRepacker](https://github.com/FEZModding/FEZRepacker), allowing you to seamlessly mod the game by injecting created and edited assets with [HAT Mod Loader](https://github.com/FEZModding/HAT).

# What are trixels?

In the most part, trixels are basically voxels, in that the bigger art pieces are made out of small grid-aligned cubes. However, unlike voxels, trixels can be colored differently on each side, allowing an artist to create more believable pixel-art when trixel-art is being projected onto the screen in the game. This is achieved by using a cubemap projection to color the created model. However, because of this solution, there are two major throwbacks of this format that you have to be aware of:

- trixel faces behind and in front of other trixel faces will always have the same color,
- triles and art objects always need to have an uniform size, otherwise cubemap could not be constructed.

This is a limitation of a format/game and not this software. In the future, this could potentially be changed by adding new projection system that a special HAT modification could support.

FEZ distinguishes two types of trixel-arts: **triles** and **art objects**.

**Triles** are meant to be stored in trile-sets, and used to build a bigger map by arranging them in a trile grid (same thing as tile grid, but in 3D), while **art objects** are additional decoration models, which aren't limited by the grid arrangement or size.

# Roadmap

- [X] Orbital camera control with ortographic mode for easy preview of each face
- [X] Optimized generation of the trile mesh
- [X] Tools for appending/removing regions of trixels with
- [X] Tools for painting cubemaps on top of triles
- [ ] Trile properties configuration (name, size, actor type)
- [ ] Manipulation of trixel regions (selection, moving, rotating, flipping, copy-pasting)
- [ ] Saving and loading trilesets and art objects with appended trixel data
- [X] Importing trilesets and art objects by generating trixel data from mesh
- [ ] Gallery of triles (for trile sets) and switching between them
- [X] Different preview modes (wireframe, flat, shaded)
- [ ] Helper construction tools (like mirror mode)

# Building

The top-most directory of this repository functions as a Godot project. However, in order for it to work properly, you have to compile GDExtension library first, using SConstruct. For that, you should be able to simply run `scons` command in both `extensions/godot-cpp` and `extensions` directories. If that fails, roughly follow the [Building the C++ bindings](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/gdextension_cpp_example.html#building-the-c-bindings) and [Compiling the plugin](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/gdextension_cpp_example.html#compiling-the-plugin) sections of the GDExtension guide for potential solutions.

Once building is done, appropriate `libfelt` binaries should be in the `bin` directory of the Godot project.
