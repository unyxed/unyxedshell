use std::path::{Path, PathBuf};

#[derive(Debug, Clone, serde::Serialize)]
pub struct Paths {
	pub local: PathBuf,
	pub roaming: PathBuf,
	pub temp: PathBuf,
	pub start_menu: PathBuf,
	pub install_dir: PathBuf,
	pub quickshell: PathBuf,
	pub shell_config: PathBuf,
	pub colors: PathBuf,
	pub settings: PathBuf,
	pub user_fonts: PathBuf,
	pub wt_fragment: PathBuf,
}

impl Paths {
	pub fn from_roots(local: &Path, roaming: &Path, temp: &Path, start_menu: &Path) -> Paths {
		let quickshell = local.join("quickshell");
		Paths {
			local: local.into(),
			roaming: roaming.into(),
			temp: temp.into(),
			start_menu: start_menu.into(),
			install_dir: local.join("unyxedshell"),
			shell_config: quickshell.join("unyxedshell"),
			colors: quickshell.join("State").join("user").join("generated").join("colors.json"),
			quickshell,
			settings: local.join("unyxedshell-config"),
			user_fonts: local.join("Microsoft").join("Windows").join("Fonts"),
			wt_fragment: local.join("Microsoft").join("Windows Terminal").join("Fragments").join("unyxedshell"),
		}
	}

	pub fn manifest(&self) -> PathBuf {
		self.install_dir.join(crate::MANIFEST)
	}
	pub fn log(&self) -> PathBuf {
		self.install_dir.join(crate::LOG)
	}
	pub fn setup_exe(&self) -> PathBuf {
		self.install_dir.join(crate::SETUP_EXE)
	}
	pub fn restore_dir(&self) -> PathBuf {
		self.install_dir.join("restore")
	}
	pub fn backup_dir(&self) -> PathBuf {
		self.install_dir.join("backup")
	}
	pub fn staging(&self) -> PathBuf {
		self.local.join("unyxedshell.staging")
	}
	pub fn previous(&self) -> PathBuf {
		self.local.join("unyxedshell.previous")
	}
	pub fn qs_exe(&self) -> PathBuf {
		self.install_dir.join("qs.exe")
	}
	pub fn qsw_exe(&self) -> PathBuf {
		self.install_dir.join("qsw.exe")
	}
	pub fn settings_qml(&self) -> PathBuf {
		self.shell_config.join("settings.qml")
	}
	pub fn default_colors(&self) -> PathBuf {
		self.shell_config.join("defaults").join("windows").join("colors.json")
	}
	pub fn quickshell_dirs(&self) -> Vec<PathBuf> {
		["unyxedshell", "State", "cache", "run"].iter().map(|d| self.quickshell.join(d)).collect()
	}
	pub fn defender_folders(&self) -> Vec<PathBuf> {
		vec![self.install_dir.clone(), self.quickshell.clone(), self.settings.clone(), self.temp.join("quickshell")]
	}
	pub fn user_state(&self) -> PathBuf {
		self.quickshell.join("State").join("user")
	}
	pub fn generic_cache(&self) -> PathBuf {
		self.local.join("cache")
	}
	pub fn ii_temp(&self) -> PathBuf {
		self.temp.join("quickshell")
	}
}
