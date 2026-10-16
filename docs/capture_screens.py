import time, os
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

BASE = "https://jwt-testing-app.onrender.com"
OUT = r"D:\TestingApp\docs\poc-images"
os.makedirs(OUT, exist_ok=True)

opts = Options()
opts.add_argument("--headless=new")
opts.add_argument("--disable-gpu")
opts.add_argument("--no-sandbox")
opts.add_argument("--window-size=1440,1400")
opts.add_argument("--hide-scrollbars")
opts.add_argument("--force-device-scale-factor=1")
for p in [r"C:\Program Files\Google\Chrome\Application\chrome.exe"]:
    if os.path.exists(p):
        opts.binary_location = p

driver = webdriver.Chrome(options=opts)
driver.set_page_load_timeout(120)


def full_page_shot(path):
    # Resize the window to the full document height so the screenshot captures everything.
    total_h = driver.execute_script(
        "return Math.max(document.body.scrollHeight, document.documentElement.scrollHeight);"
    )
    total_w = driver.execute_script(
        "return Math.max(document.body.scrollWidth, document.documentElement.scrollWidth);"
    )
    driver.set_window_size(max(1440, total_w), min(total_h + 120, 6000))
    time.sleep(1.2)
    driver.save_screenshot(path)
    print("saved", path)


def wake_and_get(url, tries=6):
    for i in range(tries):
        try:
            driver.get(url)
            return True
        except Exception as e:
            print(f"load attempt {i+1} failed: {e}; retrying...")
            time.sleep(10)
    return False


# 1) LOGIN
wake_and_get(BASE + "/login")
WebDriverWait(driver, 90).until(EC.presence_of_element_located((By.NAME, "username")))
time.sleep(1.5)
full_page_shot(os.path.join(OUT, "01-login.png"))

# 2) DASHBOARD (log in with test/test)
driver.find_element(By.NAME, "username").clear()
driver.find_element(By.NAME, "username").send_keys("test")
driver.find_element(By.NAME, "password").clear()
driver.find_element(By.NAME, "password").send_keys("test")
driver.find_element(By.CSS_SELECTOR, "button[type=submit]").click()
WebDriverWait(driver, 60).until(EC.presence_of_element_located((By.ID, "accessTokenBox")))
time.sleep(2.5)  # let the countdowns tick a moment so the numbers are populated
full_page_shot(os.path.join(OUT, "02-dashboard.png"))

# 3) DEMO SELF-TEST MATRIX
wake_and_get(BASE + "/demo")
time.sleep(3)
full_page_shot(os.path.join(OUT, "03-demo-matrix.png"))

driver.quit()
print("DONE")
