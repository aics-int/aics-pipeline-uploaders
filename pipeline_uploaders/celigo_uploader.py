import lkaccess.contexts
import requests
from aicsfiles import FileManagementSystem
from lkaccess import LabKey, QueryFilter


class CeligoUploader:
    def __init__(self, file_type, path):
        self.path = path
        self.file_type = file_type
        file_name = open(self.path).name.split("\\")[-1]

        raw_metadata = file_name.split("_")

        self.plate_barcode = raw_metadata[0]

        ts = raw_metadata[2].split("-")
        self.scan_date = ts[0] + "-" + ts[1] + "-" + ts[2]
        self.scan_time = ts[4] + "-" + ts[5] + "-" + ts[6]

        self.row = raw_metadata[4][0]
        self.col = raw_metadata[4][1:]

        lk = LabKey(server_context=lkaccess.contexts.PROD)

        my_rows = lk.select_rows_as_list(
            schema_name="microscopy",
            query_name="Plate",
            filter_array=[
                QueryFilter("Barcode", self.plate_barcode),
            ],
        )

        plate_ID = my_rows[0]["PlateId"]
        r = requests.get(
            f"http://aics.corp.alleninstitute.org/metadata-management-service/1.0/plate/{plate_ID}",
            headers={"x-user-id": "brian.whitney"},
        )
        import json

        with open("data_from_plate.json", "w") as f:
            json.dump(r.json(), f)

        self.json = "data_from_plate.json"

        self.metadata = {
            "microsocpy": {
                "plate_barcode": [self.plate_barcode],  # an existing fms file_id
                "celigo": {
                    "scan_time": [self.scan_time],
                    "scan_date": [self.scan_date],
                    "row": [self.row],
                    "coll": [self.col],
                },
            },
        }

    def upload(self):
        fms = FileManagementSystem()
        while True:
            try:
                fms.upload_file(
                    self.path, file_type=self.file_type, metadata=self.metadata
                )
                break
            except OSError:
                print("File Not Uploaded")
            except ValueError:
                print("File Not Uploaded")
            except BaseException:
                print("File Not Uploaded")
