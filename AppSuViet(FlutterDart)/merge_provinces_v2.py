import re

# Mapping: 34 tinh thanh moi = gop cac tinh cu
# Key: ten tinh moi, Value: list ten cac tinh cu can gop
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

# Tim tat ca cac path co id VN
# Pattern: <path ... id="VN\d+" ... name="..." ...>...</path>
path_pattern = r'<path\s+([^>]*id="(VN\d+)"[^>]*)>(.*?)</path>'
all_matches = re.findall(path_pattern, vn_content, re.DOTALL | re.IGNORECASE)

# Tao dictionary: key = ten tinh, value = path data
province_data = {}

for match in all_matches:
    full_attrs = match[0]
    province_id = match[1]
    path_content = match[2].strip()
    
    # Tim name attribute
    name_match = re.search(r'name="([^"]*)"', full_attrs, re.IGNORECASE)
    if name_match:
        name = name_match.group(1)
        # Tim d attribute trong path content
        d_match = re.search(r'd="([^"]*)"', path_content, re.IGNORECASE)
        if d_match:
            d_data = d_match.group(1)
            province_data[name] = d_data
        else:
            # Neu khong co d trong path content, tim trong full_attrs
            d_match = re.search(r'd="([^"]*)"', full_attrs, re.IGNORECASE)
            if d_match:
                d_data = d_match.group(1)
                province_data[name] = d_data

print(f"Found {len(province_data)} provinces with names in vn.svg")

# Doc file Vietnam_location_map.svg
with open('assets/images/Vietnam_location_map.svg', 'r', encoding='utf-8') as f:
    vietnam_map_content = f.read()

# Tim vi tri group provinces
provinces_start = vietnam_map_content.find('<g id="provinces">')
provinces_end = vietnam_map_content.find('</g>', provinces_start) if provinces_start != -1 else -1

# Tao 34 tinh thanh moi
new_provinces = []
province_counter = 1

for new_name, old_names in mapping.items():
    found_paths = []
    
    for old_name in old_names:
        # Tim kiem theo ten chinh xac
        found = False
        for prov_name, prov_d in province_data.items():
            # So sanh ten (bo khoang trang, lowercase, bo dau)
            def normalize_name(n):
                n = n.strip().lower()
                # Bo "TP. ", "Tỉnh ", etc
                n = n.replace("tp. ", "").replace("tỉnh ", "").replace("tinh ", "")
                return n
            
            if normalize_name(prov_name) == normalize_name(old_name):
                found_paths.append(prov_d)
                found = True
                break
        
        if not found:
            # Tim kiem theo ten rut gon
            for prov_name, prov_d in province_data.items():
                clean_old = old_name.replace("TP. ", "").replace("Tỉnh ", "").strip().lower()
                clean_prov = prov_name.replace("TP. ", "").replace("Tỉnh ", "").strip().lower()
                if clean_old in clean_prov or clean_prov in clean_old:
                    found_paths.append(prov_d)
                    found = True
                    break
    
    if found_paths:
        # Gop cac path data
        if len(found_paths) == 1:
            merged_data = found_paths[0]
        else:
            # Gop nhieu path: lay path dau tien, them cac path khac vao
            merged_data = found_paths[0]
            for p in found_paths[1:]:
                # Gop path data (bo M dau tien cua path thu 2 tro di)
                if p.strip().startswith('M'):
                    remaining = p.strip()[1:].lstrip()
                    if remaining:
                        merged_data += " " + remaining
        
        # Tao path moi
        new_id = f"VN{province_counter:02d}"
        new_path = f'    <path id="{new_id}" name="{new_name}" d="{merged_data}"/>\n'
        new_provinces.append(new_path)
        province_counter += 1

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





