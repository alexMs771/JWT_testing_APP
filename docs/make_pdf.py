import base64, os, time
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait

HTML = "file:///D:/TestingApp/docs/poc-render.html"
PDF = r"D:\TestingApp\POC-cf-token-manager.pdf"

opts = Options()
opts.add_argument("--headless=new")
opts.add_argument("--disable-gpu")
opts.add_argument("--no-sandbox")
opts.add_argument("--allow-file-access-from-files")
opts.add_argument("--window-size=1200,1600")
for p in [r"C:\Program Files\Google\Chrome\Application\chrome.exe"]:
    if os.path.exists(p):
        opts.binary_location = p

driver = webdriver.Chrome(options=opts)
try:
    driver.get(HTML)

    # Wait until the page signals it finished rendering (marked + mermaid.run done).
    WebDriverWait(driver, 90).until(
        lambda d: d.find_element("css selector", "body").get_attribute("data-ready") == "1"
    )

    # Confirm every mermaid block became an <svg>; wait until the count is stable.
    def counts(d):
        return d.execute_script(
            "return [document.querySelectorAll('.mermaid').length, document.querySelectorAll('.mermaid svg').length];"
        )

    stable = 0
    last = None
    for _ in range(40):
        c = counts(driver)
        if last == c and c[0] > 0 and c[1] >= c[0]:
            stable += 1
            if stable >= 3:
                break
        else:
            stable = 0
        last = c
        time.sleep(0.5)
    print("mermaid blocks/svgs:", counts(driver))

    time.sleep(1.0)

    result = driver.execute_cdp_cmd(
        "Page.printToPDF",
        {
            "printBackground": True,
            "preferCSSPageSize": True,
            "paperWidth": 8.27,
            "paperHeight": 11.69,
        },
    )
    with open(PDF, "wb") as f:
        f.write(base64.b64decode(result["data"]))
    print("PDF bytes:", os.path.getsize(PDF))
finally:
    driver.quit()
print("DONE")
