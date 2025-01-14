#ifndef TRILE_CUBEMAP_H
#define TRILE_CUBEMAP_H

#include "trile.h"
#include <godot_cpp/classes/image_texture.hpp>

namespace godot
{

class TrileCubemap : public ImageTexture
{
    GDCLASS(TrileCubemap, ImageTexture)

private:
    Ref<Trile> _trile;
    int _texture_resolution;
    Ref<Image> _buffer_image;

protected:
    static void _bind_methods();

public:
    TrileCubemap();
    ~TrileCubemap();
    static Ref<TrileCubemap> create(Ref<Trile> trile);

private:
    void _generate_image();
    void _fill_trixel_face(const Vector3i position, const Trile::Face face, const Color color);

public:
    void apply_external_image(Ref<Image> img);

    void paint(const Vector3i position, const Trile::Face face, const Color color);
    void flood_fill(const Vector3i position, const Trile::Face face, const Color color);
    Color pick_color(const Vector3i position, const Trile::Face face);

    Vector2i trixel_coords_to_texture_coords(const Vector3i coords, const Trile::Face face);
    Vector2 trile_coords_to_uv(const Vector3 coords, const Trile::Face face);

    static int get_face_texture_x_offset(const Trile::Face face);
    static Vector3 get_face_texture_tangent(const Trile::Face face);
    static Vector3 get_face_texture_cotangent(const Trile::Face face);
};

} //namespace godot

#endif // TRILE_CUBEMAP_H