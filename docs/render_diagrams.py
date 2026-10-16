import os, time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait

HTML = "file:///D:/TestingApp/docs/poc-render.html"
OUT = r"D:\TestingApp\docs\diagrams"
os.makedirs(OUT, exist_ok=True)

opts = Options()
opts.add_argument("--headless=new")
opts.add_argument("--disable-gpu")
opts.add_argument("--no-sandbox")
opts.add_argument("--allow-file-access-from-files")
opts.add_argument("--force-device-scale-factor=2")
opts.add_argument("--high-dpi-support=1")
opts.add_argument("--window-size=1400,2000")
for p in [r"C:\Program Files\Google\Chrome\Application\chrome.exe"]:
    if os.path.exists(p):
        opts.binary_location = p

driver = webdriver.Chrome(options=opts)
try:
    driver.get(HTML)
    WebDriverWait(driver, 90).until(
        lambda d: d.find_element("css selector", "body").get_attribute("data-ready") == "1"
    )
    # wait for svgs to stabilise
    last = None
    stable = 0
    for _ in range(60):
        c = driver.execute_script(
            "return [document.querySelectorAll('.mermaid').length, document.querySelectorAll('.mermaid svg').length];"
        )
        if last == c and c[0] > 0 and c[1] >= c[0]:
            stable += 1
            if stable >= 3:
                break
        else:
            stable = 0
        last = c
        time.sleep(0.5)
    print("mermaid blocks/svgs:", last)

    time.sleep(1.0)
    els = driver.find_elements("css selector", ".mermaid")
    print("diagram count:", len(els))
    for i, el in enumerate(els, start=1):
        driver.execute_script("arguments[0].scrollIntoView({block:'center'});", el)
        time.sleep(0.2)
        path = os.path.join(OUT, f"d{i:02d}.png")
        el.screenshot(path)
        print("saved", path, os.path.getsize(path))
finally:
    driver.quit()
print("DONE")
