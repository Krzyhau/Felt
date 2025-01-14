#include "trile_cubemap.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void TrileCubemap::_bind_methods()
{
    ClassDB::bind_static_method("TrileCubemap", D_METHOD("create", "trile"), &TrileCubemap::create);

    ClassDB::bind_method(D_METHOD("apply_external_image", "image"), &TrileCubemap::apply_external_image);

    ClassDB::bind_method(D_METHOD("paint", "position", "face", "color"), &TrileCubemap::paint);
    ClassDB::bind_method(D_METHOD("flood_fill", "position", "face", "color"), &TrileCubemap::flood_fill);
    ClassDB::bind_method(D_METHOD("pick_color", "position", "face"), &TrileCubemap::pick_color);

    ClassDB::bind_method(D_METHOD("trixel_coords_to_texture_coords", "coords", "face"), &TrileCubemap::trixel_coords_to_texture_coords);
    ClassDB::bind_method(D_METHOD("trile_coords_to_uv", "coords", "face"), &TrileCubemap::trile_coords_to_uv);

    ClassDB::bind_static_method("TrileCubemap", D_METHOD("get_face_texture_x_offset", "face"), &TrileCubemap::get_face_texture_x_offset);
    ClassDB::bind_static_method("TrileCubemap", D_METHOD("get_face_texture_tangent", "face"), &TrileCubemap::get_face_texture_tangent);
    ClassDB::bind_static_method("TrileCubemap", D_METHOD("get_face_texture_cotangent", "face"), &TrileCubemap::get_face_texture_cotangent);
}

TrileCubemap::TrileCubemap()
{
}

TrileCubemap::~TrileCubemap()
{
    if (_buffer_image.is_valid()) {
        _buffer_image.unref();
    }
}

Ref<TrileCubemap> TrileCubemap::create(Ref<Trile> trile)
{
    Ref<TrileCubemap> cubemap;
    cubemap.instantiate();
    cubemap->_trile = trile;
    cubemap->_generate_image();
    return cubemap;
}

void TrileCubemap::_generate_image()
{
    auto max_dimension = _trile->get_size()[_trile->get_size().max_axis_index()];
    _texture_resolution = (max_dimension * _trile->get_resolution());
    auto width = _texture_resolution * 6;
    auto height = _texture_resolution;
    _buffer_image = Image::create(width, height, false, Image::FORMAT_RGBA8);
    _buffer_image->fill(Color(1.0f, 1.0f, 1.0f, 0.0f));
    set_image(_buffer_image);
}

void TrileCubemap::_fill_trixel_face(const Vector3i position, const Trile::Face face, const Color color)
{
    auto pixel_pos = trixel_coords_to_texture_coords(position, face);
    if (!_is_texture_coords_valid(pixel_pos) || _buffer_image->get_pixelv(pixel_pos) == color) {
        return;
    }

    auto texture_tangent = Trile::get_face_tangent(face);
    auto texture_cotangent = Trile::get_face_cotangent(face);
    auto endpos = position + texture_tangent + texture_cotangent;

    auto pixel_endpos = trixel_coords_to_texture_coords(endpos, face);

    auto pixel_dir = (pixel_endpos - pixel_pos).sign();

    for (int x = pixel_pos.x; x != pixel_endpos.x; x += pixel_dir.x) {
        for (int y = pixel_pos.y; y != pixel_endpos.y; y += pixel_dir.y) {
            Vector2i subpixel_pos(x, y);
            if (_is_texture_coords_valid(subpixel_pos)) {
                _buffer_image->set_pixelv(subpixel_pos, color);
            }
        }
    }
}

bool TrileCubemap::_is_texture_coords_valid(const Vector2i coords)
{
    return coords.x >= 0 && coords.x < _buffer_image->get_width() &&
            coords.y >= 0 && coords.y < _buffer_image->get_height();
}

void TrileCubemap::apply_external_image(Ref<Image> img)
{
    set_image(img);
    _buffer_image.unref();
    _buffer_image = img;
}

void TrileCubemap::paint(const Vector3i position, const Trile::Face face, const Color color)
{
    _fill_trixel_face(position, face, color);
    set_image(_buffer_image);
}

void TrileCubemap::flood_fill(const Vector3i position, const Trile::Face face, const Color color)
{
    auto existing_color = pick_color(position, face);
    if (existing_color == color) {
        return;
    }

    std::set<Vector3i> triles_to_fill;
    std::set<Vector3i> propagation_triles;
    std::set<Vector3i> new_propagation_triles;

    auto tangent_vector = Trile::get_face_tangent(face);
    auto cotangent_vector = Trile::get_face_cotangent(face);

    propagation_triles.insert(position);

    while (!propagation_triles.empty()) {
        for (auto pos : propagation_triles) {
            triles_to_fill.insert(pos);

            std::set<Vector3i> neighbours = {
                pos + tangent_vector,
                pos - tangent_vector,
                pos + cotangent_vector,
                pos - cotangent_vector
            };

            for (auto newpos : neighbours) {
                bool not_filled_yet = triles_to_fill.find(newpos) == triles_to_fill.end();
                bool not_propagated_yet = new_propagation_triles.find(newpos) == new_propagation_triles.end();
                bool is_solid = _trile->is_trixel_face_solid(newpos, face);
                bool is_same_color = pick_color(newpos, face) == existing_color;

                if (not_filled_yet && not_propagated_yet && is_solid && is_same_color) {
                    new_propagation_triles.insert(newpos);
                }
            }
        }

        propagation_triles = new_propagation_triles;
        new_propagation_triles.clear();
    }

    for (auto pos : triles_to_fill) {
        _fill_trixel_face(pos, face, color);
    }
    set_image(_buffer_image);
}

Color TrileCubemap::pick_color(const Vector3i position, const Trile::Face face)
{
    auto pixel_pos = trixel_coords_to_texture_coords(position, face);
    if (!_is_texture_coords_valid(pixel_pos)) {
        return Color();
    }
    return _buffer_image->get_pixelv(pixel_pos);
}

Vector2i TrileCubemap::trixel_coords_to_texture_coords(const Vector3i coords, const Trile::Face face)
{
    auto texture_based_offset = Vector3(1, 1, 1) * (0.5f / _trile->get_resolution());
    texture_based_offset *= _trile->get_size() * (_trile->get_resolution() / (float)_texture_resolution);
    auto trixel_local_mid_pos = _trile->trixel_to_local(coords) + texture_based_offset;
    auto uv_coords = trile_coords_to_uv(trixel_local_mid_pos, face);
    auto texture_pos = uv_coords * (Vector2)(_buffer_image->get_size());
    auto pixel_pos = texture_pos.floor();
    return (Vector2i)pixel_pos;
}

Vector2 TrileCubemap::trile_coords_to_uv(const Vector3 coords, const Trile::Face face)
{
    auto texture_offset_x = get_face_texture_x_offset(face);

    auto face_normal = (Vector3)Trile::get_face_normal(face);

    auto trixel_scaled_position = ((Vector3)coords) / ((Vector3)_trile->get_size());
    auto texture_plane_pos = (Vector3(1, 1, 1) - face_normal.abs()) * trixel_scaled_position;
    texture_plane_pos += (face_normal + Vector3(1, 1, 1)) * 0.5f;

    auto tangent = get_face_texture_tangent(face);
    auto cotangent = get_face_texture_cotangent(face);

    auto x_coord = texture_plane_pos.dot(tangent);
    x_coord = (x_coord + texture_offset_x) / 6.0f;

    auto y_coord = texture_plane_pos.dot(cotangent);

    if (face != Trile::Face::TOP) {
        y_coord = 1.0f - y_coord;
    }

    return Vector2(x_coord, y_coord);
}

int TrileCubemap::get_face_texture_x_offset(const Trile::Face face)
{
    static const int offset_lookup[] = {
        0, // FRONT
        3, // BACK
        4, // TOP
        5, // BOTTOM
        3, // LEFT
        2 // RIGHT
    };
    return offset_lookup[face];
}

Vector3 TrileCubemap::get_face_texture_tangent(const Trile::Face face)
{
    static const Vector3 tangent_lookup[] = {
        Vector3(1, 0, 0), // FRONT
        Vector3(-1, 0, 0), // BACK
        Vector3(1, 0, 0), // TOP
        Vector3(1, 0, 0), // BOTTOM
        Vector3(0, 0, 1), // LEFT
        Vector3(0, 0, -1), // RIGHT
    };
    return tangent_lookup[face];
}

Vector3 TrileCubemap::get_face_texture_cotangent(const Trile::Face face)
{
    static const Vector3 cotangent_lookup[] = {
        Vector3(0, 1, 0), // FRONT
        Vector3(0, 1, 0), // BACK
        Vector3(0, 0, 1), // TOP
        Vector3(0, 0, 1), // BOTTOM
        Vector3(0, 1, 0), // LEFT
        Vector3(0, 1, 0), // RIGHT
    };
    return cotangent_lookup[face];
}
