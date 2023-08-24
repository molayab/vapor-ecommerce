import SideMenu from "./SideMenu";

function Loader() {
    return (
        <SideMenu>
            <div className="flex flex-col items-center justify-center h-full">
                <div className="loader ease-linear rounded-full border-8 border-t-8 border-gray-200 h-64 w-64"></div>
            </div>
        </SideMenu>
    )
}

export default Loader