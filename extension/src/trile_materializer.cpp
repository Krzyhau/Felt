#include "trile_materializer.h"
#include "trile_cubemap.h"
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

TrileMaterializer::TrileMaterializer(Ref<Trile> trile)
{
    _trile = trile;
}

TrileMaterializer::~TrileMaterializer()
{
}

void TrileMaterializer::materialize()
{
    auto array_mesh = _create_materialized_mesh();
    _trile->set_raw_mesh(array_mesh);
}

Array TrileMaterializer::_create_materialized_mesh()
{
    std::vector<Vector3> mesh_vertices = {};
    std::vector<Vector2> mesh_uvs = {};

    for (int i = 0; i < 6; i++) {
        auto face = (Trile::Face)i;
        auto layer_dir = Trile::get_face_normal_abs(face);
        auto layer_dir_depth = _trile->get_trixel_width_along_axis(layer_dir);

        for (int layer = 0; layer < layer_dir_depth; layer++) {
            auto planes = _find_planes_in_layer(face, layer);
            for (const auto &plane : planes) {
                _add_plane_to_mesh(plane, mesh_vertices, mesh_uvs);
            }
        }
    }

    auto mesh_vertices_array = PackedVector3Array();
    auto mesh_uvs_array = PackedVector2Array();

    for (const auto &vertex : mesh_vertices) {
        mesh_vertices_array.push_back(vertex);
    }
    for (const auto &uv : mesh_uvs) {
        mesh_uvs_array.push_back(uv);
    }

    auto mesh_data = Array();
    mesh_data.resize(Mesh::ARRAY_MAX);
    mesh_data[Mesh::ARRAY_VERTEX] = mesh_vertices_array;
    mesh_data[Mesh::ARRAY_TEX_UV] = mesh_uvs_array;

    return mesh_data;
}

std::list<TrileMaterializer::TrixelPlane> TrileMaterializer::_find_planes_in_layer(Trile::Face face, int depth)
{
    auto dir_x = Trile::get_face_tangent_abs(face);
    auto dir_y = Trile::get_face_cotangent_abs(face);
    auto dir_z = Trile::get_face_normal_abs(face);

    auto layer_size_x = _trile->get_trixel_width_along_axis(dir_x);
    auto layer_size_y = _trile->get_trixel_width_along_axis(dir_y);
    auto layer_size_z = _trile->get_trixel_width_along_axis(dir_z);

    auto x_index = (dir_x.x != 0) ? _trile->get_x_index() : ((dir_x.y != 0) ? _trile->get_y_index() : _trile->get_z_index());
    auto y_index = (dir_y.x != 0) ? _trile->get_x_index() : ((dir_y.y != 0) ? _trile->get_y_index() : _trile->get_z_index());
    auto z_index = (dir_z.x != 0) ? _trile->get_x_index() : ((dir_z.y != 0) ? _trile->get_y_index() : _trile->get_z_index());

    auto face_normal = Trile::get_face_normal(face);
    auto depth_offset = (face_normal.x + face_normal.y + face_normal.z);
    auto abs_depth = (depth_offset > 0) ? depth : (layer_size_z - 1 - depth);
    auto z_offset = abs_depth * z_index;
    auto z_top_offset = z_offset + depth_offset * z_index;

    auto has_top = depth + 1 < layer_size_z;

    auto buffer = _trile->get_raw_trixel_buffer();

    auto plane_map = std::vector<bool>(layer_size_x * layer_size_y, false);

    for (int x = 0; x < layer_size_x; x++) {
        for (int y = 0; y < layer_size_y; y++) {
            auto trixel_index = x * x_index + y * y_index + z_offset;
            auto top_trixel_index = x * x_index + y * y_index + z_top_offset;

            auto state = buffer[trixel_index] && !(has_top && buffer[top_trixel_index]);
            plane_map[x + y * layer_size_x] = state;
        }
    }

    auto layer_planes = _greedy_mesh_planes_in_layer(plane_map, layer_size_x, layer_size_y);

    auto trixel_planes = std::list<TrileMaterializer::TrixelPlane>();
    for (const auto &plane : layer_planes) {
        auto pos = dir_x * plane.pos.x + dir_y * plane.pos.y + dir_z * abs_depth;
        trixel_planes.push_back({ pos, plane.size, face });
    }

    return trixel_planes;
}

std::list<TrileMaterializer::LayerPlane> TrileMaterializer::_greedy_mesh_planes_in_layer(std::vector<bool> layer_map, int width, int height)
{
    std::list<TrileMaterializer::LayerPlane> planes;

    for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
            if (!layer_map[x + y * width]) {
                continue;
            }
            layer_map[x + y * width] = false;

            auto plane_size = Vector2i(1, 1);

            while (x + plane_size.x < width) {
                auto face_index = x + plane_size.x + y * width;
                if (!layer_map[face_index]) {
                    break;
                }
                layer_map[face_index] = false;
                plane_size.x++;
            }

            while (y + plane_size.y < height) {
                int line_width = 0;
                while (line_width < plane_size.x) {
                    auto face_index = x + line_width + (y + plane_size.y) * width;
                    if (!layer_map[face_index]) {
                        break;
                    }
                    line_width++;
                }

                if (line_width != plane_size.x) {
                    break;
                }
                for (int dX = 0; dX < plane_size.x; dX++) {
                    auto face_index = x + dX + (y + plane_size.y) * width;
                    layer_map[face_index] = false;
                }
                plane_size.y++;
            }

            planes.push_back({ Vector2i(x, y), plane_size });
        }
    }

    return planes;
}

void TrileMaterializer::_add_plane_to_mesh(const TrileMaterializer::TrixelPlane plane, std::vector<Vector3> &mesh_vertices, std::vector<Vector2> &mesh_uvs)
{
    auto face_normal = Trile::get_face_normal(plane.face);
    auto dir_x = Trile::get_face_tangent(plane.face);
    auto dir_y = Trile::get_face_cotangent(plane.face);

    auto face_corner = (Vector3)plane.pos + (Vector3(1, 1, 1) + face_normal - (dir_x + dir_y)) * 0.5f;
    auto face_offset_x = (Vector3)(dir_x * plane.size.x);
    auto face_offset_y = (Vector3)(dir_y * plane.size.y);

    float resolution = _trile->get_resolution();
    face_corner = (face_corner / resolution) - _trile->get_size() * 0.5f;
    face_offset_x /= resolution;
    face_offset_y /= resolution;

    auto face_vertices = std::vector{
        face_corner,
        face_corner + face_offset_x,
        face_corner + face_offset_x + face_offset_y,
        face_corner + face_offset_y
    };

    std::vector<Vector2> uvs;
    for (int i = 0; i < 4; i++) {
        uvs.push_back(_trile->get_cubemap()->trile_coords_to_uv(face_vertices[i], plane.face));
    }

    // this check is a result of using abs on tangent vectors
    const int indices_clockwise[] = { 2, 1, 0, 0, 3, 2 };
    const int indices_counter_clockwise[] = { 0, 1, 2, 2, 3, 0 };

    auto use_clockwise = face_normal.x < 0 || face_normal.y < 0 || face_normal.z < 0;
    auto indices = use_clockwise ? indices_clockwise : indices_counter_clockwise;

    for (int i = 0; i < 6; i++) {
        mesh_vertices.push_back(face_vertices[indices[i]]);
        mesh_uvs.push_back(uvs[indices[i]]);
    }
}