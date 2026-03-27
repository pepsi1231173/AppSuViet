import re
import xml.etree.ElementTree as ET

# Mapping: 34 tinh thanh moi = gop cac tinh cu
mapping = {
    "An Giang": ["Kiên Giang", "An Giang"],
    "Bắc Ninh": ["Bắc Giang", "Bắc Ninh"],
    "Cà Mau": ["Bạc Liêu", "Cà Mau"],
    "Cao Bằng": ["Cao Bằng"],
    "TP. Cần Thơ": ["Sóc Trăng", "Hậu Giang", "TP. Cần Thơ"],
    "TP. Đà Nẵng": ["Quảng Nam", "TP. Đà Nẵng"],
    "Đắk Lắk": ["Phú Yên", "Đắk Lắk"],
    "Điện Biên": ["Điện Biên"],
    "Đồng Nai": ["Bình Phước", "Đồng Nai"],
    "Đồng Tháp": ["Tiền Giang", "Đồng Tháp"],
    "Gia Lai": ["Gia Lai", "Bình Định"],
    "TP. Hà Nội": ["TP. Hà Nội"],
    "Hà Tĩnh": ["Hà Tĩnh"],
    "TP. Hải Phòng": ["Hải Dương", "TP. Hải Phòng"],
    "TP. Hồ Chí Minh": ["Bình Dương", "TP. Hồ Chí Minh", "Bà Rịa – Vũng Tàu"],
    "TP. Huế": ["TP. Huế"],
    "Hưng Yên": ["Thái Bình", "Hưng Yên"],
    "Khánh Hoà": ["Khánh Hòa", "Ninh Thuận"],
    "Lai Châu": ["Lai Châu"],
    "Lạng Sơn": ["Lạng Sơn"],
    "Lào Cai": ["Lào Cai", "Yên Bái"],
    "Lâm Đồng": ["Đắk Nông", "Lâm Đồng", "Bình Thuận"],
    "Nghệ An": ["Nghệ An"],
    "Ninh Bình": ["Hà Nam", "Ninh Bình", "Nam Định"],
    "Phú Thọ": ["Hòa Bình", "Vĩnh Phúc", "Phú Thọ"],
    "Quảng Ngãi": ["Quảng Ngãi", "Kon Tum"],
    "Quảng Ninh": ["Quảng Ninh"],
    "Quảng Trị": ["Quảng Bình", "Quảng Trị"],
    "Sơn La": ["Sơn La"],
    "Tây Ninh": ["Long An", "Tây Ninh"],
    "Thái Nguyên": ["Bắc Kạn", "Thái Nguyên"],
    "Thanh Hóa": ["Thanh Hóa"],
    "Tuyên Quang": ["Hà Giang", "Tuyên Quang"],
    "Vĩnh Long": ["Bến Tre", "Vĩnh Long", "Trà Vinh"]
}

# Doc file vn.svg
with open('assets/images/vn.svg', 'r', encoding='utf-8') as f:
    vn_content = f.read()

# Tim tat ca cac path co id VN va name
path_pattern = r'<path\s+([^>]*id="VN\d+"[^>]*name="([^"]*)"[^>]*)>(.*?)</path>'
all_paths = re.findall(path_pattern, vn_content, re.DOTALL | re.IGNORECASE)

# Tao dictionary de tim path theo ten
province_paths = {}
for match in all_paths:
    full_attr = match[0]
    name = match[1]
    path_data = match[2]
    # Tim id
    id_match = re.search(r'id="(VN\d+)"', full_attr, re.IGNORECASE)
    if id_match:
        province_id = id_match.group(1)
        province_paths[name] = {
            'id': province_id,
            'attrs': full_attr,
            'data': path_data.strip()
        }

print(f"Found {len(province_paths)} provinces in vn.svg")

# Doc file Vietnam_location_map.svg
with open('assets/images/Vietnam_location_map.svg', 'r', encoding='utf-8') as f:
    vietnam_map_content = f.read()

# Tim vi tri group provinces hoac tao moi
provinces_start = vietnam_map_content.find('<g id="provinces">')
provinces_end = vietnam_map_content.find('</g>', provinces_start) if provinces_start != -1 else -1

# Tao 34 tinh thanh moi
new_provinces = []
province_counter = 1

for new_name, old_names in mapping.items():
    # Tim cac path cua cac tinh cu
    found_paths = []
    for old_name in old_names:
        # Tim kiem theo ten (co the co khoang trang hoac khong)
        found = False
        for prov_name, prov_data in province_paths.items():
            # So sanh ten (bo khoang trang va chuyen thanh lowercase)
            if prov_name.strip().lower() == old_name.strip().lower():
                found_paths.append(prov_data['data'])
                found = True
                break
            # Tim kiem theo ten rut gon (bo "TP. ", "Tỉnh ", etc)
            clean_old = old_name.replace("TP. ", "").replace("Tỉnh ", "").strip().lower()
            clean_prov = prov_name.replace("TP. ", "").replace("Tỉnh ", "").strip().lower()
            if clean_old == clean_prov:
                found_paths.append(prov_data['data'])
                found = True
                break
        
        if not found:
            pass  # Khong tim thay
    
    if found_paths:
        # Gop cac path data lai (neu co nhieu tinh)
        if len(found_paths) == 1:
            merged_data = found_paths[0]
        else:
            # Gop nhieu path: lay path dau tien, them cac path khac vao
            merged_data = found_paths[0]
            for p in found_paths[1:]:
                # Gop path data (bo M dau tien cua path thu 2 tro di)
                if p.strip().startswith('M'):
                    # Lay tu ky tu thu 2 (bo M dau tien)
                    remaining = p.strip()[1:].lstrip()
                    if remaining:
                        merged_data += " " + remaining
        
        # Tao path moi
        new_id = f"VN{province_counter:02d}"
        new_path = f'    <path id="{new_id}" name="{new_name}" d="{merged_data}"/>\n'
        new_provinces.append(new_path)
        province_counter += 1
    else:
        pass  # Khong tim thay path

# Tao group provinces moi
provinces_group = '  <g id="provinces">\n'
provinces_group += ''.join(new_provinces)
provinces_group += '  </g>\n'

# Thay the hoac them vao file
if provinces_start != -1 and provinces_end != -1:
    # Thay the group cu
    new_content = vietnam_map_content[:provinces_start] + provinces_group + vietnam_map_content[provinces_end + 4:]
else:
    # Them vao truoc VietNamFlag
    insert_marker = '<g id="VietNamFlag"'
    if insert_marker in vietnam_map_content:
        insert_pos = vietnam_map_content.find(insert_marker)
        new_content = vietnam_map_content[:insert_pos] + provinces_group + '\n' + vietnam_map_content[insert_pos:]
    else:
        # Them vao truoc </svg>
        insert_pos = vietnam_map_content.rfind('</svg>')
        new_content = vietnam_map_content[:insert_pos] + provinces_group + vietnam_map_content[insert_pos:]

# Ghi lai file
with open('assets/images/Vietnam_location_map.svg', 'w', encoding='utf-8') as f:
    f.write(new_content)

print(f"Created {len(new_provinces)} merged provinces in Vietnam_location_map.svg")

