import { Card, Metric, Subtitle } from "@tremor/react";
import SideMenu from "../components/SideMenu";

function FeatureNotAvailable() {
  return (
    <SideMenu>
        <Card>
            <Metric className="mb-4">Funcionalidad no disponible</Metric>
            <Subtitle>Esta funcionalidad ha sido desactivada por el administrador</Subtitle>
        </Card>
    </SideMenu>
  );
}

export default FeatureNotAvailable;