#include "trile_dematerializer.h"
#include <godot_cpp/variant/array.hpp>

using namespace godot;

TrileDematerializer::TrileDematerializer(Ref<Trile> trile)
{
    _trile = trile;
    _sandwich_data = new SandwichState[_trile->get_trixels_count()];
}

TrileDematerializer::~TrileDematerializer()
{
    delete _sandwich_data;
}

void TrileDematerializer::dematerialize()
{
    _populate_sandwich_data();
    _rasterize_trile_mesh();
}

// returns an array defining where "sandwiching" begins and ends in voxel data
void TrileDematerializer::_populate_sandwich_data()
{
    auto mesh_arrays = _trile->surface_get_arrays(0);
    auto mesh_vertices = (PackedVector3Array)mesh_arrays[Mesh::ARRAY_VERTEX];
    auto mesh_normals = (PackedVector3Array)mesh_arrays[Mesh::ARRAY_NORMAL];

    auto trile_offset = _trile->get_size() * 0.5f;

    for (int i = 0; i < mesh_vertices.size(); i += 3)
    {
        auto x_normal = SIGN(mesh_normals[i].x + mesh_normals[i + 1].x + mesh_normals[i + 2].x);
        x_normal = (x_normal > 0.0f) ? 1.0f : (x_normal < 0.0f ? -1.0f : 0.0f);
        if(x_normal == 0.0f) continue;

        auto v1 = (mesh_vertices[i + 0] + trile_offset) * _trile->get_resolution();
        auto v2 = (mesh_vertices[i + 1] + trile_offset) * _trile->get_resolution();
        auto v3 = (mesh_vertices[i + 2] + trile_offset) * _trile->get_resolution();

        auto plane_normal = (v2 - v1).normalized().cross((v3 - v1).normalized()).normalized();
        auto plane_d = plane_normal.dot(v1);
        if(plane_normal.x == 0.0f) continue;

        auto pv1 = Vector2(v1.y, v1.z);
        auto pv2 = Vector2(v2.y, v2.z);
        auto pv3 = Vector2(v3.y, v3.z);

        auto line1 = Vector2(pv2.y - pv1.y, pv1.x - pv2.x).normalized();
        auto d1 = line1.dot(pv1);
        auto s1 = SIGN(d1 - line1.dot(pv3));
        d1 += s1 * 0.05;

        auto line2 = Vector2(pv3.y - pv2.y, pv2.x - pv3.x).normalized();
        auto d2 = line2.dot(pv2);
        auto s2 = SIGN(d2 - line2.dot(pv1));
        d2 += s2 * 0.05;

        auto line3 = Vector2(pv1.y - pv3.y, pv3.x - pv1.x).normalized();
        auto d3 = line3.dot(pv3);
        auto s3 = SIGN(d3 - line3.dot(pv2));
        d3 += s3 * 0.05;

        auto min_x = CLAMP(floorf(MIN(MIN(pv1.x, pv2.x), pv3.x)), 0, _trile->get_z_index() - 1);
        auto min_y = CLAMP(floorf(MIN(MIN(pv1.y, pv2.y), pv3.y)), 0, _trile->get_trixels_count() - 1);
        auto max_x = CLAMP(ceilf(MAX(MAX(pv1.x, pv2.x), pv3.x)), 0, _trile->get_z_index() - 1);
        auto max_y = CLAMP(ceilf(MAX(MAX(pv1.y, pv2.y), pv3.y)), 0, _trile->get_trixels_count() - 1);
    
        for(int x=min_x;x<max_x;x++) for(int y=min_y;y<max_y;y++){
            auto point = Vector2(x + 0.5, y + 0.5);

            // check if point is within the triangle
            if(s1 != SIGN(d1 - line1.dot(point))) continue;
            if(s2 != SIGN(d2 - line2.dot(point))) continue;
            if(s3 != SIGN(d3 - line3.dot(point))) continue;

            // within triangle - calculate depth from plane formula
            auto depth = roundf((plane_d - point.x * plane_normal.y - point.y * plane_normal.z) / plane_normal.x);
            if(depth >= _trile->get_y_index()) continue;

            depth = CLAMP(depth, 0, _trile->get_y_index() - 1);

            int index = depth + x * _trile->get_y_index() + y * _trile->get_z_index();
            auto curr_state = _sandwich_data[index];
            SandwichState new_state = plane_normal.x > 0.0 ? ENTRY : EXIT;
            if (curr_state != 0 && curr_state != new_state) new_state = BOTH;
            _sandwich_data[index] = new_state;
        }
    }
}

void TrileDematerializer::_rasterize_trile_mesh()
{
    bool* buffer = _trile->get_raw_trixel_buffer();

    SandwichState state;
    for (int i = 0; i< _trile->get_trixels_count(); i++)
    {
        if (i % _trile->get_y_index() == 0 || state == EXIT){
            state = NONE;
        }
        if(_sandwich_data[i] == ENTRY) state = ENTRY;
        if(_sandwich_data[i] == EXIT) state = NONE;
        if(_sandwich_data[i] == BOTH) state = EXIT;

        if(state != NONE) buffer[i] = true;
    }
}


