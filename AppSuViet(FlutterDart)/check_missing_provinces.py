import re

# Mapping: 34 tinh thanh moi
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
        # Tim d attribute trong path content hoac full_attrs
        d_match = re.search(r'd="([^"]*)"', path_content, re.IGNORECASE)
        if not d_match:
            d_match = re.search(r'd="([^"]*)"', full_attrs, re.IGNORECASE)
        if d_match:
            d_data = d_match.group(1)
            province_data[name] = d_data

print(f"Found {len(province_data)} provinces with names in vn.svg")

# Doc file Vietnam_location_map.svg
with open('assets/images/Vietnam_location_map.svg', 'r', encoding='utf-8') as f:
    vietnam_map_content = f.read()

# Tim cac tinh da tao
created_provinces = re.findall(r'name="([^"]*)"', vietnam_map_content)
created_provinces = [p for p in created_provinces if p in mapping.keys()]

print(f"Created {len(created_provinces)} provinces in Vietnam_location_map.svg")

# Tim cac tinh chua tao
missing_provinces = [name for name in mapping.keys() if name not in created_provinces]
print(f"Missing {len(missing_provinces)} provinces:")
for i, name in enumerate(sorted(missing_provinces), 1):
    old_names = mapping[name]
    print(f"  {i}. {name}")
    print(f"     Needs: {len(old_names)} old provinces")
    # Tim xem cac tinh cu co trong vn.svg khong
    for old_name in old_names:
        found = False
        for prov_name in province_data.keys():
            if old_name.lower() in prov_name.lower() or prov_name.lower() in old_name.lower():
                found = True
                break
        if not found:
            print(f"     -> NOT FOUND: {old_name}")

