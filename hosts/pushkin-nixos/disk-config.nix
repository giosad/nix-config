{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/ata-SanDisk_SSD_PLUS_240GB_1907DB801623";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
      ssd = {
        type = "disk";
        device = "/dev/disk/by-id/ata-SanDisk_SSD_PLUS_1000GB_214401A00277";
        content = {
          type = "gpt";
          partitions = {
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/ssd";
              };
            };
          };
        };
      };
      hdd = {
        type = "disk";
        device = "/dev/disk/by-id/ata-WDC_WD10EZEX-00RKKA0_WD-WCC1S4603472";
        content = {
          type = "gpt";
          partitions = {
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/hdd";
              };
            };
          };
        };
      };
    };
  };
}
