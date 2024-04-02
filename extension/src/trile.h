#ifndef TRILE_H
#define TRILE_H

#include <godot_cpp/classes/array_mesh.hpp>
#include <godot_cpp/classes/shader_material.hpp>

namespace godot
{
    class TrileCubemap;

    class Trile : public ArrayMesh
    {
        GDCLASS(Trile, ArrayMesh)
    
    public:
        enum Face : int
        {
            FRONT,
            BACK,
            TOP,
            BOTTOM,
            LEFT,
            RIGHT
        };

    private:
        bool _should_dematerialize;
        Ref<ShaderMaterial> _material;
        Ref<TrileCubemap> _cubemap;

    private:
        bool *_buffer;
        int _resolution;
        Vector3 _size;
        Vector3i _trixel_bounds;
        int _trixels_count;
        int _x_index;
        int _y_index;
        int _z_index;

    public:
        bool *get_raw_trixel_buffer();
        PackedByteArray get_trixel_buffer();
        void set_trixel_buffer(const PackedByteArray buffer);
        int get_resolution();
        Vector3 get_size();
        Vector3i get_trixel_bounds();
        int get_trixels_count();
        int get_x_index();
        int get_y_index();
        int get_z_index();
        Ref<TrileCubemap> get_cubemap();
        Ref<ShaderMaterial> get_material();
        void set_material(Ref<ShaderMaterial>);

    private:
        void _set_size_snapped_to_grid(Vector3 size);
        void _recalculate_constants();
        void _initialize_data_buffer();
        void _initialize_cubemap();

    protected:
        static void _bind_methods();
    
    public:
        Trile();
        ~Trile();
        static Ref<Trile> create(const Vector3 trile_size, const int trile_resolution);

        void rebuild_mesh();
        void set_raw_mesh(const Array mesh_data);

        int get_trixel_width_along_axis(const Vector3i axis);
        bool contains_trixel_pos(const Vector3i pos);

        int trixel_index_from_position(const Vector3i pos);
        bool get_trixel(const Vector3i pos);
        bool get_adjacent_trixel(const Vector3i pos, const Face face);
        bool is_trixel_face_solid(const Vector3i pos, const Face face);
        void set_trixel(const Vector3i pos, const bool state);
        void set_trixels(const TypedArray<Vector3i> positions, const bool state);
        void fill_trixels(const Vector3i start_corner, const Vector3i end_corner, const bool state);

        Vector3 trixel_to_local(const Vector3 trixel_pos);
        Vector3 local_to_trixel(const Vector3 local_pos);

        static Vector3i get_face_normal(const Face face);
        static Vector3i get_face_normal_abs(const Face face);
        static Vector3i get_face_tangent(const Face face);
        static Vector3i get_face_tangent_abs(const Face face);
        static Vector3i get_face_cotangent(const Face face);
        static Vector3i get_face_cotangent_abs(const Face face);

        static Face face_from_normal(const Vector3i normal);
        static String get_face_name(const Face face);
        static Vector3 get_face_rotation_degrees(const Face face);
    };

}

VARIANT_ENUM_CAST(Trile::Face);

#endif // TRILE_H