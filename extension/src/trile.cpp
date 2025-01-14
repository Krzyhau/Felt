#include "trile.h"
#include "trile_cubemap.h"
#include "trile_dematerializer.h"
#include "trile_materializer.h"
#include <godot_cpp/classes/shader_material.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void Trile::_bind_methods()
{
    ClassDB::bind_static_method("Trile", D_METHOD("create", "trile_size", "trile_resolution"), &Trile::create);

    ClassDB::bind_method(D_METHOD("get_trixel_buffer"), &Trile::get_trixel_buffer);
    ClassDB::bind_method(D_METHOD("set_trixel_buffer", "buffer"), &Trile::set_trixel_buffer);
    ClassDB::bind_method(D_METHOD("get_resolution"), &Trile::get_resolution);
    ClassDB::bind_method(D_METHOD("get_size"), &Trile::get_size);
    ClassDB::bind_method(D_METHOD("get_trixel_bounds"), &Trile::get_trixel_bounds);
    ClassDB::bind_method(D_METHOD("get_trixels_count"), &Trile::get_trixels_count);
    ClassDB::bind_method(D_METHOD("get_x_index"), &Trile::get_x_index);
    ClassDB::bind_method(D_METHOD("get_y_index"), &Trile::get_y_index);
    ClassDB::bind_method(D_METHOD("get_z_index"), &Trile::get_z_index);
    ClassDB::bind_method(D_METHOD("get_cubemap"), &Trile::get_cubemap);
    ClassDB::bind_method(D_METHOD("get_material"), &Trile::get_material);
    ClassDB::bind_method(D_METHOD("set_material", "material"), &Trile::set_material);

    ClassDB::bind_method(D_METHOD("rebuild_mesh"), &Trile::rebuild_mesh);
    ClassDB::bind_method(D_METHOD("set_raw_mesh"), &Trile::set_raw_mesh);
    ClassDB::bind_method(D_METHOD("get_trixel_width_along_axis", "axis"), &Trile::get_trixel_width_along_axis);
    ClassDB::bind_method(D_METHOD("contains_trixel_pos", "pos"), &Trile::contains_trixel_pos);
    ClassDB::bind_method(D_METHOD("get_trixel", "pos"), &Trile::get_trixel);
    ClassDB::bind_method(D_METHOD("get_adjacent_trixel", "pos", "face"), &Trile::get_adjacent_trixel);
    ClassDB::bind_method(D_METHOD("is_trixel_face_solid", "pos", "face"), &Trile::is_trixel_face_solid);
    ClassDB::bind_method(D_METHOD("set_trixel", "pos", "state"), &Trile::set_trixel);
    ClassDB::bind_method(D_METHOD("set_trixels", "positions", "state"), &Trile::set_trixels);
    ClassDB::bind_method(D_METHOD("fill_trixels", "start_corner", "end_corner", "state"), &Trile::fill_trixels);

    ClassDB::bind_method(D_METHOD("trixel_to_local", "trixel_pos"), &Trile::trixel_to_local);
    ClassDB::bind_method(D_METHOD("local_to_trixel", "local_pos"), &Trile::local_to_trixel);

    ClassDB::bind_static_method("Trile", D_METHOD("get_face_normal", "face"), &Trile::get_face_normal);
    ClassDB::bind_static_method("Trile", D_METHOD("get_face_normal_abs", "face"), &Trile::get_face_normal_abs);
    ClassDB::bind_static_method("Trile", D_METHOD("get_face_tangent", "face"), &Trile::get_face_tangent);
    ClassDB::bind_static_method("Trile", D_METHOD("get_face_tangent_abs", "face"), &Trile::get_face_tangent_abs);
    ClassDB::bind_static_method("Trile", D_METHOD("get_face_cotangent", "face"), &Trile::get_face_cotangent);
    ClassDB::bind_static_method("Trile", D_METHOD("get_face_cotangent_abs", "face"), &Trile::get_face_cotangent_abs);

    ClassDB::bind_static_method("Trile", D_METHOD("face_from_normal", "normal"), &Trile::face_from_normal);
    ClassDB::bind_static_method("Trile", D_METHOD("get_face_name", "face"), &Trile::get_face_name);
    ClassDB::bind_static_method("Trile", D_METHOD("get_face_rotation_degrees", "face"), &Trile::get_face_rotation_degrees);
}

Trile::Trile()
{
    _should_dematerialize = false;
    _resolution = 0;
    _size = Vector3();
    _trixel_bounds = Vector3i();
    _trixels_count = 0;
    _x_index = 0;
    _y_index = 0;
    _z_index = 0;
}

Trile::~Trile()
{
}

Ref<Trile> Trile::create(const Vector3 trile_size, const int trile_resolution)
{
    Ref<Trile> trile;
    trile.instantiate();
    trile->_resolution = trile_resolution;
    trile->_set_size_snapped_to_grid(trile_size);
    trile->_recalculate_constants();

    trile->_initialize_data_buffer();
    trile->_initialize_cubemap();
    return trile;
}

std::vector<bool> &Trile::get_raw_trixel_buffer()
{
    return _buffer;
}

PackedByteArray Trile::get_trixel_buffer()
{
    PackedByteArray array;
    array.resize(_trixels_count);
    for (int i = 0; i < _trixels_count; i++) {
        array.push_back(_buffer[i]);
    }
    return array;
}

void godot::Trile::set_trixel_buffer(const PackedByteArray buffer)
{
    for (int i = 0; i < MIN(_trixels_count, buffer.size()); i++) {
        _buffer[i] = buffer[i];
    }
}

int Trile::get_resolution()
{
    return _resolution;
}

Vector3 Trile::get_size()
{
    return _size;
}

Vector3i Trile::get_trixel_bounds()
{
    return _trixel_bounds;
}

int Trile::get_trixels_count()
{
    return _trixels_count;
}

int Trile::get_x_index()
{
    return _x_index;
}

int Trile::get_y_index()
{
    return _y_index;
}

int Trile::get_z_index()
{
    return _z_index;
}

Ref<TrileCubemap> Trile::get_cubemap()
{
    return _cubemap;
}

Ref<ShaderMaterial> Trile::get_material()
{
    return _material;
}

void Trile::set_material(Ref<ShaderMaterial> material)
{
    _material = material;
    if (_material.is_valid()) {
        _material->set_shader_parameter("TEXTURE", _cubemap);
        if (get_surface_count() > 0) {
            surface_set_material(0, _material);
        }
    }
}

void Trile::_initialize_data_buffer()
{
    _buffer = { false };
    _buffer.resize(_trixels_count);
}

void Trile::_set_size_snapped_to_grid(Vector3 size)
{
    _size = (size * _resolution).round() / _resolution;
}

void Trile::_recalculate_constants()
{
    _trixel_bounds = _size * _resolution;
    _trixels_count = _trixel_bounds.x * _trixel_bounds.y * _trixel_bounds.z;

    _x_index = 1;
    _y_index = _trixel_bounds.x;
    _z_index = _trixel_bounds.x * _trixel_bounds.y;
}

void Trile::_initialize_cubemap()
{
    _cubemap = TrileCubemap::create(this);
}

void Trile::rebuild_mesh()
{
    if (_should_dematerialize) {
        TrileDematerializer(this).dematerialize();
    }
    TrileMaterializer(this).materialize();
    _should_dematerialize = false;
}

void Trile::set_raw_mesh(const Array mesh_data)
{
    clear_surfaces();

    auto vertices = (PackedVector3Array)mesh_data[Mesh::ARRAY_VERTEX];
    if (vertices.size() == 0) {
        return;
    }

    add_surface_from_arrays(PRIMITIVE_TRIANGLES, mesh_data);
    if (_material.is_valid()) {
        surface_set_material(0, _material);
    }
    _should_dematerialize = true;
}

int Trile::get_trixel_width_along_axis(const Vector3i axis)
{
    auto axis_size = _trixel_bounds * axis;
    return abs(axis_size.x + axis_size.y + axis_size.z);
}

bool Trile::contains_trixel_pos(const Vector3i pos)
{
    return pos.x >= 0 && pos.x < _trixel_bounds.x &&
            pos.y >= 0 && pos.y < _trixel_bounds.y &&
            pos.z >= 0 && pos.z < _trixel_bounds.z;
}

int Trile::trixel_index_from_position(const Vector3i pos)
{
    return pos.x * _x_index + pos.y * _y_index + pos.z * _z_index;
}

bool Trile::get_trixel(const Vector3i pos)
{
    if (!contains_trixel_pos(pos)) {
        return false;
    } else {
        return _buffer[trixel_index_from_position(pos)];
    }
}

bool Trile::get_adjacent_trixel(const Vector3i pos, const Trile::Face face)
{
    return get_trixel(pos + get_face_normal(face));
}

bool Trile::is_trixel_face_solid(const Vector3i pos, const Trile::Face face)
{
    return get_trixel(pos) && !get_adjacent_trixel(pos, face);
}

void Trile::set_trixel(const Vector3i pos, const bool state)
{
    if (contains_trixel_pos(pos)) {
        _buffer[trixel_index_from_position(pos)] = state;
    }
}

void Trile::set_trixels(const TypedArray<Vector3i> positions, const bool state)
{
    for (int i = 0; i < positions.size(); i++) {
        set_trixel(positions[i], state);
    }
}

void Trile::fill_trixels(const Vector3i start_corner, const Vector3i end_corner, const bool state)
{
    int start_x = MAX(MIN(start_corner.x, end_corner.x), 0);
    int start_y = MAX(MIN(start_corner.y, end_corner.y), 0);
    int start_z = MAX(MIN(start_corner.z, end_corner.z), 0);

    int end_x = MIN(MAX(start_corner.x, end_corner.x), _trixel_bounds.x - 1);
    int end_y = MIN(MAX(start_corner.y, end_corner.y), _trixel_bounds.y - 1);
    int end_z = MIN(MAX(start_corner.z, end_corner.z), _trixel_bounds.z - 1);

    for (int x = start_x; x <= end_x; x++) {
        for (int y = start_y; y <= end_y; y++) {
            for (int z = start_z; z <= end_z; z++) {
                set_trixel(Vector3i(x, y, z), state);
            }
        }
    }
}

Vector3 Trile::trixel_to_local(const Vector3 trixel_pos)
{
    return (trixel_pos / _resolution) - _size / 2.0f;
}

Vector3 Trile::local_to_trixel(const Vector3 local_pos)
{
    return (local_pos + _size / 2.0) * _resolution;
}

Vector3i Trile::get_face_normal(const Trile::Face face)
{
    static const Vector3i normal_lookup[] = {
        Vector3i(0, 0, 1), // FRONT
        Vector3i(0, 0, -1), // BACK
        Vector3i(0, 1, 0), // TOP
        Vector3i(0, -1, 0), // BOTTOM
        Vector3i(-1, 0, 0), // LEFT
        Vector3i(1, 0, 0), // RIGHT
    };
    return normal_lookup[face];
}

Vector3i Trile::get_face_normal_abs(const Trile::Face face)
{
    return get_face_normal(face).abs();
}

Vector3i Trile::get_face_tangent(const Trile::Face face)
{
    static const Vector3i tangent_lookup[] = {
        Vector3i(0, 1, 0), // FRONT
        Vector3i(0, 1, 0), // BACK
        Vector3i(1, 0, 0), // TOP
        Vector3i(1, 0, 0), // BOTTOM
        Vector3i(0, 0, 1), // LEFT
        Vector3i(0, 0, 1), // RIGHT
    };
    return tangent_lookup[face];
}

Vector3i Trile::get_face_tangent_abs(const Trile::Face face)
{
    return get_face_tangent(face).abs();
}

Vector3i Trile::get_face_cotangent(const Trile::Face face)
{
    static const Vector3i tangent_lookup[] = {
        Vector3i(1, 0, 0), // FRONT
        Vector3i(1, 0, 0), // BACK
        Vector3i(0, 0, 1), // TOP
        Vector3i(0, 0, 1), // BOTTOM
        Vector3i(0, 1, 0), // LEFT
        Vector3i(0, 1, 0), // RIGHT
    };
    return tangent_lookup[face];
}

Vector3i Trile::get_face_cotangent_abs(const Trile::Face face)
{
    return get_face_cotangent(face).abs();
}

Trile::Face Trile::face_from_normal(const Vector3i normal)
{
    static const Face face_lookup[] = {
        BACK,
        BOTTOM,
        LEFT,
        (Face)0,
        RIGHT,
        TOP,
        FRONT,
    };
    auto face_index = normal.x + normal.y * 2 + normal.z * 3 + 3;
    if (face_index >= 0 && face_index <= 6) {
        return face_lookup[face_index];
    }
    return TOP;
}

String Trile::get_face_name(const Face face)
{
    static const String face_names[] = { "Front", "Back", "Top", "bottom", "Left", "Right" };
    return face_names[face];
}

Vector3 Trile::get_face_rotation_degrees(const Face face)
{
    static const Vector3 rotation_lookup[] = {
        Vector3(0, 0, 0), // FRONT
        Vector3(0, 180, 0), // BACK
        Vector3(-90, 0, 0), // TOP
        Vector3(90, 0, 0), // BOTTOM
        Vector3(0, 270, 0), // LEFT
        Vector3(0, 90, 0), // RIGHT
    };
    return rotation_lookup[face];
}
